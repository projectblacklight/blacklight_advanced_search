# == User-entered queries handled ==
#    * simple lists of terms and phrases, possibly with + or -, are translated 
#      directly to dismax queries, respecting whatever mm is operative for the
#      Blacklight search field definition (either as a specified mm param in the
#      search field definition, or in Solr request handler default)
#      * one two three
#      * one +two -"three phrase"
#
#    * AND/OR/NOT operators can be used for boolean logic. Parenthesis can
#      be used to be clear about grouping, or to make arbitrarily complex
#      nested logic. These operators always apply to only the immediately
#      adjacent terms, unless parens are used, and "OR" 'binds more tightly'
#      than 'AND'
#      * big OR small AND blue OR green === (big OR small) AND (blue OR green)
#      * one AND two OR three AND four   ===    one AND (two OR three) AND four
#      ** alternative, with different meaning:  (one AND two) OR (three AND four)
#      * NOT one two three ===  (NOT one) two three === -one two three
#      ** alternative, with different meaning: NOT(one two three)
#      
#    * lists of terms can be combined with AND/OR/NOT in a variety of ways
#    ** one two three OR four  === one two (three OR four)
#    ** (one two three) AND (big small medium)
#    ** NOT(one two) three ((four OR -five) AND (blue green red))
#    *** Note that some of these latter ones can have confusing semantics
#        if your dismax mm isn't 100%.  For instance (one two three) will be
#        a dismax query, let's say mm=1, then the result set would actually
#        be the equivalent of (one OR two OR three). NOT(one two three) will
#        be an actual complementary NOT, the complementary/inverted set --
#        so NOT(one two three) (if you had dismax mm=1) will essentially 
#        have the same semantics as NOT(one OR two OR three), which isn't
#        neccesarily what the user is expecting. But if the user always uses
#        explicit boolean connectors, they can exert complete control over
#        the semantics, and not get the 'fuzziness'. Alternately, the local
#        implementer could use only mm=100%, in which case everything is much
#        less fuzzy/hard-to-predict
#
# == Conversion to Solr ==
#
# As mentioned, a straight list of terms such as (in the most complicated)
# case: << one -two +"three four" >> is translated directly to a dismax
# query for those entered terms. Using the qf/pf/mm/etc you have configured
# for the Blacklight search_field in question. (While by default the advanced
# search plugin uses exactly the same field configurations you already have
# for simple search, you could also choose to pass in different ones for
# advanced search, perhaps setting mm to 100% if desired for adv search)
#
# There are a few motivations for doing things this way:
# * To be consistent with simple search, so moving to advanced is less of a 
#   conceptual break for the user. If you take a legal simple search, and
#   enter it in a given field in advanced search, it will work exactly the
#   same as it did in simple (even if mm is not 100% in simple), rather than
#   having entirely different semantics.
# * Taking advantage of that, one might eventually want to actually use this
#   parser in simple search, so user can enter single-field boolean expressions
#   even in simple/basic search.
# * In the future, we might want to provide actual fielded searches in an
#   'expert' mode. << title: foo AND author:bar >> or 
#   << (title:(one two) AND author:(three four)) OR isbn:X >>
#   For explicit fielded searching, it is convenient if you can combine
#   dismax searches. 
#
# Once you start putting boolean operators AND, OR, NOT in, the query will
# no longer neccesarily be converted to a _single_ nested dismax query, a single
# user-entered string may be converted to multiple nested queries. In some
# common cases, multiple clauses will still be collapsed into fewer dismax
# queries than the 'naive' translation. Examples:
#
#   * one two three (blue AND green AND -purple)
#       => _query_:"{!dismax}one two three +four +five -purple"
#   * one two three (blue OR green OR purple)
#       => _query_:"{!dismax}one two three" AND _query_:"{!dismax mm=1}blue green purple"
#
#   However, if you use complicated crazy nesting, you can get a lot of nested
#   queries generated:
#     * ((one two) AND (three OR four)) OR (blue AND NOT (green OR purple))
#        => "( ( _query_:"{!dismax }one two" AND _query_:"{!dismax mm=1}three four" ) OR ( _query_:"{!dismax }blue" AND NOT _query_:"{!dismax mm=1}green purple" ) )"
#
# = Note on pure negative queries =
# In Solr 1.4.1, the dismax query parser can't handle queries with only "-"
# excluded terms. And while the lucene query parser can handle certain types
# of pure negative queries, it can't properly handle a NOT(x) as one of the
# operands of the "OR".  Our query generation strategy notices these cases
# and transforms to semantically equivalent query that can be handled by
# Solr properly. At least it tries, this is the least clean part of the code.
# But there are specs showing it works for some fairly complicated queries. 
#
# -one -two  =>is transformed to=>  NOT _query_:"{!dismax mm=1}one two"
# $x OR NOT $y =>is transformed to=> $x OR (*:* AND NOT $y)
#
# works with very complicated queries when the bad pure negative part
# would be just a sub-clause or sub-query. Sometimes the result is not
# the most concise query possible, but it should hold to it's semantics. 
#
# -red -blue (-foo OR -bar) (big OR NOT small)
#    ==>
# NOT _query_:"{!dismax mm=1}red blue" AND NOT _query_:"{!dismax mm=100%}foo bar" AND ( _query_:\"{!dismax }big" OR (*:* AND NOT _query_:"{!dismax }small") )
#
# = Why not use e-dismax? =
#
# That would be a potentially reasonable choice. Why didn't I? 
#
# One, at the time of this writing, edismax is not available in a tagged stable
# Solr release, and I write code for Blacklight that works with tagged stable
# releases. 
#
# Two, edismax doesn't neccesarily entirely support the semantics I want,
# especially for features I would like to add in the future. I am not sure
# exactly what edismax does with complicated deeply nested expressions. 
# For fielded searches, dismax supports actual individual solr fields, but not
# the "fields" as dismax qf aggregates that we need. These things could
# be added to dismax, but with my lack of Java chops and familiarity with
# Solr code, it would have taken me much longer to do (and been much less
# enjoyable). 
#
# I think it may be a reasonable choice to seperate concerns between Solr
# and the app layer like this, let Solr handle basic search expressions,
# but let the app layer handle more complicated query parsing, translating
# to those simple expressions. 
#
# On the other hand, there are definite downsides to this approach. Including
# having to deal with idiosyncracies of built-in query parsers ("pure
# negative" behavior), depend upon other idiosyncracies (dismax does not
# apply mm to -excluded terms), etc. And not being able to share the code
# at the Solr/Java level. 
#
# In the future, a different approach that might be best of all could be
# using the not-yet-finished XML query parser, to do initial parsing in
# ruby at the app level, but translate to specified lucene primitives using
# XML query parser, instead of having to translate to lucene/dismax query
# parsers. 
#
# = Future Enhancement Ideas =
# Just ideas. 
# 
# 1. Allow expert "fielded" searches. title:foo
#    which would correspond not to actual solr index field "title", but
#    to a Blacklight-configured "search field" qf/pf. 
# 2. Insert this app-level parser even in "simple" search, so users
#    can use boolean operators even in a single-fielded simple search. 
# 3. Allow a different set of qf to be used for any "phrase term", so
#    phrases would search only on non-stemming fields. This would be cool,
#    but kind of do weird things with dismax mm effects, since it would
#    mean all phrases would be extracted into seperate nested queries. 
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
    
    # build_nested_query, in addition to conveniently turning your params and query
    # into a nested query handling escaping
    def build_nested_query(embeddables, solr_params={})
      # if it's pure negative, we need to transform
      if embeddables.find_all{|n| n.kind_of?(ExcludedClause)}.length == embeddables.length
        negated = NotExpression.new( List.new(embeddables.collect {|n| n.operand}))
        solr_params = solr_params.merge(:mm => "1")        
        negated.to_query(solr_params)              
      else
            
      '_query_:"' + 
        bs_escape(build_local_params(solr_params) + 
        embeddables.collect {|n| n.to_embed}.join(" ")) + 
        '"'

      end      
    end
    
    
    
    def build_local_params(hash = {})
      # we insist on dismax for our embedded queries. 
      hash = hash.dup
      hash.delete("defType") ; hash.delete(:defType)
      
      "{!dismax " +  hash.collect {|k,v| "#{k}=#{  v.to_s.include?(" ") ? "'"+v+"'" : v }"}.join(" ") + "}"      
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


