module ParsingNesting::Tree
  
  # Get parslet output for string (parslet output is json-y objects), and
  # transform to an actual abstract syntax tree made up of more semantic
  # ruby objects, Node's. The top one will always be a List. 
  # 
  # Call #to_query on resulting Node in order to transform to Solr query,
  # optionally passing in Solr params to be used as LocalParams in nested
  # dismax queries. 
  #
  # Our approach here works, but as we have to put in special cases
  # it starts getting messy. Ideally we might want to actually transform
  # the Object graph (abstract syntax tree) instead of trying to handle
  # special cases in #to_query. 
  # For instance, transform object graph for a problematic pure-negative
  # clause to the corresponding object graph without that (-a AND -b) ==>
  # (NOT (a OR b).  Transform (NOT NOT a) to (a). That would probably be
  # more robust. But instead we handle special cases in to_query, which
  # means the special cases tend to multiply and need to be handled at
  # multiple levels. But it's working for now.
  #
  # the #negate method was an experiment in transforming parse tree in
  # place, but isn't being used. But it's left as a sign post. 
  def self.parse(string)
    to_node_tree(ParsingNesting::Grammar.new.parse(string))
  end
  

  # theoretically Parslet's Transform could be used for this, but I think the
  # manner in which I'm parsing to Parslet labelled hash isn't exactly what
  # Parslet Transform is set up to work with, I couldn't figure it out. But
  # easy enough to do 'manually'.
  def self.to_node_tree(tree)
    if tree.kind_of? Array  
      # at one point I was normalizing top-level lists of one item to just
      # be that item, no list wrapper. But having the list wrapper
      # at the top level is actually useful for Solr output.       
      List.new( tree.collect {|i| to_node_tree(i)})      
    elsif tree.kind_of? Hash       
      if list = tree[:list]
        List.new( list.collect {|i| to_node_tree(i)} )
      elsif tree.has_key?(:and_list)
        AndList.new( tree[:and_list].collect{|i| to_node_tree(i)  } )
      elsif tree.has_key?(:or_list)
        OrList.new( tree[:or_list].collect{|i| to_node_tree(i)  } )
      elsif not_payload = tree[:not_expression]
        NotExpression.new( to_node_tree(not_payload) )
      elsif tree.has_key?(:mandatory)
        MandatoryClause.new( to_node_tree(tree[:mandatory]  ))
      elsif tree.has_key?(:excluded)
        ExcludedClause.new( to_node_tree(tree[:excluded]))
      elsif phrase = tree[:phrase]
        Phrase.new( phrase )
      elsif tree.has_key?(:token)
        Term.new( tree[:token].to_s  )
      end
    end
  end
  
  class Node
    # this default to_query works well for anything that is embeddable in
    # a standard way. 
    # non-embeddable nodes will have to override and do it different. 
    def to_query(solr_params)
      build_nested_query([self], solr_params)
    end
    
    protected # some utility methods
    
    # Builds a query from a list of Node's that have #to_embed, and some
    # solr params to embed as LocalParams.
    #
    # By default will create a nested _query_, handling escaping appropriately.
    # but pass in :always_nested=>false, and it will sometimes be an ordinary 
    # query where possible. (possibly still with LocalParams).  
    #
    # LocalParams will be default have "!dismax" added to them, but set
    # :force_deftype to something else (or nil) if you want.
    #
    # Also takes care of simple "pure negative" queries like "-one -two",
    # converting them to a nested NOT query that will be handled appropriately.
    # those simple negatives can't be handled right by dismax otherwise. 
    def build_nested_query(embeddables, solr_params={}, options = {})
      options = {:always_nested => true, 
      :force_deftype => "dismax"}.merge(options)
      
      # if it's pure negative, we need to transform
      if embeddables.find_all{|n| n.kind_of?(ExcludedClause)}.length == embeddables.length
        negated = NotExpression.new( List.new(embeddables.collect {|n| n.operand}))
        solr_params = solr_params.merge(:mm => "1")        
        return negated.to_query(solr_params)              
      else
      
        inner_query = build_local_params(solr_params, options[:force_deftype]) + 
          embeddables.collect {|n| n.to_embed}.join(" ")
        
        if options[:always_nested]       
          return '_query_:"' + bs_escape(inner_query) + '"'
        else
          return inner_query
        end

      end      
    end
            
    
    # Pass in nil 2nd argument if you DON'T want to embed
    # "!dismax" in your local params. Used by #to_single_query_params
    def build_local_params(hash = {}, force_deftype = "dismax")
      # we insist on dismax for our embedded queries, or whatever
      # other defType supplied in 2nd argument. 
      hash = hash.dup
      if force_deftype
        hash[:defType] = force_deftype
        hash.delete("defType") # avoid weird colision with hard to debug results
      end      
            
      if (hash.size > 0)
        defType = hash.delete(:defType) || hash.delete("defType")
        "{!" + (defType ? "#{defType} " : "") +  hash.collect {|k,v| "#{k}=#{  v.to_s.include?(" ") ? "'"+v+"'" : v }"}.join(" ") + "}"
      else
        #no local params!
        ""
      end
    end
    
    def bs_escape(val, char='"')
      # crazy double escaping to actually get a single backslash
      # in there without triggering regexp capture reference
      val.gsub(char, '\\\\' + char)
    end
  end
    
  
  class List < Node
    attr_accessor :list
    def initialize(aList)
      self.list = aList
    end
    def can_embed?
      false
    end
    
    def simple_pure_negative?      
      (list.find_all {|i|  i.kind_of? ExcludedClause }.length) == list.length      
    end  
    
    def to_query(solr_params={})
      queries = []
      
      (embeddable, gen_full_query) = list.partition {|i| i.respond_to?(:can_embed?) && i.can_embed?}
       
      unless embeddable.empty?
        queries << build_nested_query(embeddable, solr_params)
      end
      
      gen_full_query.each do |node|
        queries << node.to_query(solr_params)
      end
      
      queries.join(" AND ")
    end

    # Returns a Hash, assumes this will be the ONLY :q, used for
    # parsing 'simple search' to Solr. Pass in params that need to
    # be LOCAL solr params (using "{foo=bar}" embedded in query). 
    # Params that should be sent to Solr seperately are caller's responsibility,
    # merge em into the returned hash. 
    #
    # For very simple queries, this will produce an ordinary Solr q
    # much like would be produced ordinarily. But for AND/OR/NOT, will
    # sometimes include multiple nested queries instead. 
    #
    # This method will still sometimes return a single nested _query_, that
    # could theoretically really be ordinary query possibly with localparams.
    # It still works, but isn't optimizing for a simpler query, because
    # it's using much of the same code used for combining multiple fields
    # that need nested queries. Maybe we'll optimize later, but the code
    # gets tricky. 
    def to_single_query_params(solr_local_params)
      # Can it be expressed in a single dismax?
      
      if list.find_all {|i| i.respond_to?(:can_embed?) && i.can_embed? }.length == list.length        
        { 
          #build_local_params(solr_local_params, nil) + list.collect {|n| n.to_embed}.join(" "),
          :q => build_nested_query(list, solr_local_params, :always_nested => false, :force_deftype => nil), 
          :defType => "dismax"
        }        
      else
        # Can't be expressed in a single dismax, do it the normal way
        { 
          :q => self.to_query(solr_local_params),
          :defType => "lucene" 
        }
      end
    end
    
    def negate
      List.new(list.collect {|i| i.negate})
    end

  end
  
  class AndList < List
    
    # We make an and-list embeddable only if all it's elements
    # are embeddable, then no problem we just embed them all
    # as Solr '+' mandatory, and achieve the AND.
    # For now, pure negative is considered not embeddable, although
    # theoretically it could sometimes be embedded if transformed
    # properly. 
    def can_embed?
      (! simple_pure_negative?) && ! list.collect {|i| i.can_embed?}.include?(false)
    end
                    
    # Only if all operands are embeddable.
    # Trick is if they were bare terms/phrases, we add a '+' on
    # front, but if they already were +/-, then we don't need to,
    # and leaving them along will have desired semantics. 
    # This works even on "-", because dismax mm seems to not consider "-"
    # clauses, they are always required regardless of mm. 
    def to_embed
      list.collect do |operand|
        s = operand.to_embed
        if s =~ /^\+/ || s =~ /^\-/
          s
        else
          '+'+s
        end
      end.join(" ")
    end
    
    # for those that aren't embeddable, or pure negative
    def to_query(local_params)
      if simple_pure_negative?
        # Can do it in one single nested dismax, if we're simple arguments
        # that are pure negative. 
        # build_nested_query will handle negating the pure negative for
        # us. 
        build_nested_query(list, local_params)
      else      
            "( " + 
        list.collect do |i|
          i.to_query(local_params)
        end.join(" AND ") +
       " )"
      end
    end
    
    # convent logical property here, not(a AND b) === not(a) OR not(b) 
    def negate
      OrList.new( list.collect {|n| n.negate}  )
    end
    
  end
  
  
  class OrList < List  
  
    # never embeddable
    def can_embed?
      false
    end
    
    
    def to_query(local_params)
      # Okay, we're never embeddable as such, but sometimes we can
      # turn our operands into one single nested dismax query with mm=1, when
      # all our operands are 'simple', other times we need to actually do
      # two seperate nested queries seperated by lucene OR. 
      # If all our children are embeddable but _not_ an "AndList", we can
      # do the one query part. The AndList is theoretically embeddable, but
      # not in a way compatible with flattening an OR to one query. 
      # Sorry, this part is one of the least clean part of this code!

      not_flattenable = list.find {|i| ! (i.can_embed? && ! i.kind_of?(AndList) )}
      
      if not_flattenable
        to_multi_queries(local_params)
      elsif simple_pure_negative?
        to_simple_pure_negative_query(local_params)
      else
        to_one_dismax_query(local_params)
      end
    end
    
    # build_nested_query isn't smart enough to handle refactoring
    # a simple pure negative "OR", that needs an mm of 100%. 
    # Let's just do it ourselves. What we're doing makes more sense
    # if you remember that:
    # -a OR -b   ===   NOT (a AND b)
    def to_simple_pure_negative_query(local_params)
      # take em out of their ExcludedClauses
      embeddables = list.collect {|n| n.operand}
      # and insist on mm 100%
      solr_params = local_params.merge(:mm => "100%")
      
      # and put the NOT in front to preserve semantics. 
      return 'NOT _query_:"' + 
          bs_escape(build_local_params(solr_params) + 
          embeddables.collect {|n| n.to_embed}.join(" ")) + 
        '"'
    end
    
    # all our arguments are 'simple' (terms and phrases with +/-), 
    # put am all in one single dismax with mm forced to 1. 
    def to_one_dismax_query(local_params)            
      build_nested_query(list, local_params.merge(:mm => "1"))
    end
    
    def to_multi_queries(local_params)      
      "( " + 
        list.collect do |i|
        if i.kind_of?(NotExpression)  || (i.respond_to?(:simple_pure_negative?) && i.simple_pure_negative?)
            # need special handling to work around Solr 1.4.1's lack of handling
            # of pure negative in an OR
            "(*:* AND #{i.to_query(local_params)})"
          else
            i.to_query(local_params)
          end
        end.join(" OR ") +
       " )"      
    end
    
    # convenient logical property here, not(a OR b) === not(a) AND not(b)
    def negate
      AndList.new( list.collect {|n| n.negate})
    end
  
  end
  
  
  class NotExpression 
    def initialize(exp)
      self.operand = exp
    end
    attr_accessor :operand
    
    # We have to do the weird thing with *:* AND NOT (real thing), because
    # Solr 1.4.1 seems not to be able to handle "x OR NOT y" otherwise, at least
    # in some cases, but does fine with
    # "x OR (*:* AND NOT y)", which should mean the same thing.
    def to_query(solr_params)
      # rescue double-nots to not treat them crazy-like and make the query
      # more work for Solr than it needs to be with a double-negative.       
      if operand.kind_of?(NotExpression)
        operand.operand.to_query(solr_params)
      else
        "NOT " + operand.to_query(solr_params)
      end
    end
    
    def can_embed?
      false
    end
    
    
     
    def negate
      operand
    end
  end
  
  class MandatoryClause < Node
    attr_accessor :operand
    def initialize(v)
      self.operand = v
    end
    
    def can_embed?
      #right now '+' clauses only apply to terms/phrases
      #which we can embed with a + in front. 
      true
    end
    def to_embed
      '+' + operand.to_embed
    end

    # negating mandatory to excluded is decent semantics, although
    # it's not strictly 'true', it's a choice. 
    def negate
      ExcludedClause.new( operand )
    end
  end
  
  class ExcludedClause < Node
    attr_accessor :operand
    
    def initialize(v)
      self.operand = v
    end    
    
    def can_embed?
      #right now '-' clauses only apply to terms/phrases, which
      #we can embed with a '-' in front. 
      true
    end
    
    def to_embed
      '-' + operand.to_embed
    end
    
    # negating excluded to mandatory is a pretty decent choice
    def negate
      MandatoryClause.new( operand )
    end
    
    def simple_pure_negative?
      true
    end
    
  end
  
  
  class Phrase < Node
    attr_accessor :value
    
    def initialize(string)
      self.value = string
    end
    
    def can_embed?
      true
    end
    
    def to_embed
      '"' + value + '"'
    end
    
    def negate
      ExcludedClause.new(self)
    end
  end
  
  class Term < Node
    attr_accessor :value  
    
    def initialize(string)
      self.value = string
    end

    def can_embed?
      true
    end
    
    def to_embed
      value
    end    
    
    def negate
      ExcludedClause.new(self)
    end
  end
end


