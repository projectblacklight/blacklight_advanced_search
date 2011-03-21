require 'rubygems'
require 'parslet'

# Parslet uses Object#tap, which is in ruby 1.8.7+, but not 1.8.6. 
# But it's easy enough to implement in pure ruby, let's monkey patch
# it in if it's not there, so we'll still work with 1.8.6
unless Object.method_defined?(:tap)
  class Object
    def tap
      yield(self)
      return self
    end
  end
end
module ParsingNesting
  class Grammar < Parslet::Parser
    root :query
    
    # query is actually a list of expressions. 
    rule :query do
      (spacing? >>  (expression | paren_unit ) >> spacing?).repeat
    end
    
    rule :paren_list do
      (str('(') >> query >> str(')')).as(:list)
    end
    
    rule :paren_unit do
      (str('(') >> spacing? >> (expression ) >> spacing? >> str(')')) |
        paren_list
    end
    
    # Note well: It was tricky to parse the thing we want where you can
    # have a flat list with boolean operators, but where 'OR' takes precedence.
    # eg "A AND B OR C AND C" or "A OR B AND C OR D". Tricky to parse at all,
    # tricky to make precedence work. Important things that seem to make it work:
    # and_list comes BEFORE or_list in :expression.
    # and_list's operand can be an or_list, but NOT vice versa
    # There are others, it was an iterative process with testing. 
    rule :expression do
      (and_list | or_list | unary_expression )
    end
      
    rule :and_list do
      ((or_list | unary_expression | paren_unit) >> 
        (spacing >> str("AND") >> spacing >> (or_list | unary_expression | paren_unit)).repeat(1)).as(:and_list) 
    end
    
    rule :or_list do
      ((unary_expression | paren_unit) >> 
      (spacing >> str("OR") >> spacing >> (unary_expression | paren_unit)).repeat(1)).as(:or_list) 
    end
      
    rule :unary_expression do
      (str('+') >> (phrase | token)).as(:mandatory) |
      (str('-') >> (phrase | token)).as(:excluded) |
      (str('NOT') >> spacing? >> (unary_expression | paren_unit)).as(:not_expression) |
      (phrase | token)
    end
    
    rule :token do
      match['^ ":)('].repeat(1).as(:token)
    end
    rule :phrase do
      match('"') >> match['^"'].repeat(1).as(:phrase)  >> match('"')  
    end
    
    
    rule :spacing do
      match[' '].repeat(1)    
    end
    rule :spacing? do
      spacing.maybe
    end
  end

  
end
