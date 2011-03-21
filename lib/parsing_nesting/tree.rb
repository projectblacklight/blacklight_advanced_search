
module ParsingNesting::Tree

  def self.parse(string)
    to_node_tree(ParsingNesting::Grammar.new.parse(string))
  end
  
  # pass in Parlset parsed node tree, get back
  # an Array of actual ruby objects representing different kinds of nodes
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
    # this default to_query works well for anything that is embeddable.
    # non-embeddable nodes will have to override and do it different. 
    def to_query(solr_params)
      build_nested_query(to_embed, solr_params)
    end
    
    protected # some utility methods
    
    # build_nested_query, in addition to conveniently turning your params and query
    # into a nested query handling escaping
    def build_nested_query(query_literal, solr_params={})
      '_query_:"' + bs_escape(build_local_params(solr_params) + query_literal) + '"'
    end
    
    
    
    def build_local_params(hash = {})
      # we insist on dismax for our embedded queries. 
      hash = hash.dup
      hash.delete("defType") ; hash.delete(:defType)
      
      "{!dismax " +  hash.collect {|k,v| "#{k}=#{  v.include?(" ") ? "'"+v+"'" : v }"}.join(" ") + "}"      
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
    
      
    
    def to_query(solr_params={})
      queries = []
      
      (embeddable, gen_full_query) = list.partition {|i| i.respond_to?(:can_embed?) && i.can_embed?}
       
      unless embeddable.empty?
        queries << build_nested_query(embeddable.collect {|n| n.to_embed}.join(" "), solr_params)
      end
      
      gen_full_query.each do |node|
        queries << node.to_query(solr_params)
      end
      
      queries.join(" AND ")
    end
    
    def negate
      List.new(list.collect {|i| i.negate})
    end

  end
  
  class AndList < List
    
    # We make an and-list embeddable only if all it's elements
    # are embeddable, then no problem we just embed them all
    # as Solr '+' mandatory, and achieve the AND
    def can_embed?
      ! list.collect {|i| i.can_embed?}.include?(false)
    end
            
    # Only if all operands are embeddable.
    # Trick is if they were bare terms/phrases, we add a '+' on
    # front, but if they already were +/-, then we don't need to,
    # and leaving them along will have desired semantics. 
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
    
    # for those that aren't embeddable
    def to_query(local_params)
            "( " + 
        list.collect do |i|
          i.to_query(local_params)
        end.join(" AND ") +
       " )"  
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
        to_two_queries(local_params)
      else
        to_one_dismax_query(local_params)
      end
    end
    
    # all our arguments are 'simple' (terms and phrases with +/-), 
    # put am all in one single dismax with mm forced to 1. 
    def to_one_dismax_query(local_params)
      query = list.collect {|n| n.to_embed }.join(" ")
      
      build_nested_query(query, local_params.merge(:mm => "1"))
    end
    
    def to_two_queries(local_params)      
      "( " + 
        list.collect do |i|
          if i.kind_of? NotExpression
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

# tests
# foo
# "foo"
# "foo bar"
# " foo bar "
# "foo bar" baz
# baz "foo bar" baz bam
# +foo
# -foo
# +"foo"
# foo AND bar
# foo AND bar AND baz
# blue OR white AND big  # operator precedence, OR takes precedence
# breaking on the double space, why. p.parse("A AND  B OR C AND D AND E")
# A AND B AND C

