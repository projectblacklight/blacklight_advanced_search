require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
#require 'rubygems'
#require 'parslet'
#require 'spec'
#require 'spec/autorun'

#load '../../nesting_parser/grammar.rb'
#load '../../nesting_parser/tree.rb'

module ParseTreeSpecHelper
  include ParsingNesting::Tree
  
  def parse(s)
    ParsingNesting::Tree.parse(s)
  end
  
  # for things expected to be a one-element list, 
  # make sure they are and return the element
  def parse_one_element(s)
    l = parse(s)
    l.should be_kind_of( List )
    l.list.length.should == 1
    return l.list.first
  end
  
  def should_be_and_list(graph)
    graph.should be_kind_of( AndList )
    yield graph.list if block_given?
  end
  
  def should_be_list(graph)
    graph.should be_kind_of( List)
    yield graph.list if block_given?
  end
  
  def should_be_or_list(graph)
    graph.should be_kind_of( OrList )
    yield graph.list if block_given?
  end
  
  def should_be_term(graph, value)
    graph.should be_kind_of( Term )
    graph.value.should == value
  end
  
  def should_be_phrase(graph, value)
    graph.should be_kind_of( Phrase )
    graph.value.should == value
  end
  
  def should_be_mandatory(graph)
    graph.should be_kind_of(MandatoryClause)
    yield graph.operand if block_given?
  end
  def should_be_excluded(graph)
    graph.should be_kind_of(ExcludedClause)
    yield graph.operand if block_given?
  end
  def should_be_not_expression(graph)
    graph.should be_kind_of(NotExpression)
    yield graph.operand if block_given?
  end
end

describe "NestingParser" do
 describe "Building an Object parse tree" do
    include ParseTreeSpecHelper
        
    
    it "should build for term list" do
      should_be_list parse("one two three")  do |list|
        list.length.should == 3
        should_be_term list[0], "one"
        should_be_term list[1], "two"
        should_be_term list[2], "three"        
      end            
    end
    
    it "should build AND list" do
      should_be_and_list parse_one_element("one AND two AND three") do |list|
        list.length.should == 3
        
        should_be_term list[0], "one"
        should_be_term list[1], "two"
        should_be_term list[2], "three"        
      end
    end
    
    it "should build OR list" do
      should_be_or_list parse_one_element("one OR two OR three") do |list|        
        list.length.should == 3
        should_be_term list[0], "one"
        should_be_term list[1], "two"
        should_be_term list[2], "three"                  
      end                  
    end
    
    it "allows AND list of lists" do
      should_be_and_list parse_one_element('(one two) AND (blue yellow)') do |and_list|
        and_list.length.should == 2
        should_be_list and_list[0] do |list|
          should_be_term(list[0], "one")
          should_be_term(list[1], "two")
        end
        should_be_list and_list[1]
      end      
    end
    
    it "should build for mandatory and excluded" do
      should_be_list parse("+one -two") do |list|
        list.length.should == 2
        
        should_be_mandatory list[0] do |operand|
          should_be_term(operand, "one")
        end
        
        should_be_excluded list[1] do |operand|
          should_be_term(operand, "two")
        end
      end            
    end
    
    it "should build phrases" do
      should_be_list parse('"quick brown" +"jumps over" -"lazy dog"') do |list|
        list.length.should == 3
        
        should_be_phrase(list[0], "quick brown")
      
        should_be_mandatory(list[1]) do |operand|
          should_be_phrase(operand, "jumps over")
        end  
      end
    end
    
    it "should leave phrase literals literal, including weird chars" do
      phrase_content = "foo+bar -i: '(baz" 
      should_be_phrase parse_one_element("\"#{phrase_content}\""), phrase_content      
    end
    
    it "should build for NOT on term" do
      should_be_list parse("one two three NOT four") do |list|
        should_be_not_expression list[3] do |operand|
          should_be_term(operand, "four")
        end
      end            
    end
    
    it "should build for NOT on phrase" do
      should_be_list parse('one two three NOT "quick brown"') do |list|
        should_be_not_expression list[3] do |operand|
          should_be_phrase(operand, "quick brown")
        end
      end      
    end
    
    it "should build NOT on expression" do
      should_be_list parse('one two NOT (blue OR yellow)') do |list|
        should_be_not_expression list[2] do |operand|
          should_be_or_list(operand)
        end
      end            
    end
    
    it "should build NOT preceded by binary op" do
      should_be_or_list parse_one_element('one OR NOT two') do |list|
        should_be_not_expression list[1] do |operand|
          should_be_term(operand, "two")
        end
      end              
    end
      
    
    it "should bind OR more tightly than AND" do
      should_be_and_list parse_one_element("grey AND big OR small AND tail") do |list|        
        list.length.should == 3
        
        should_be_term list[0], "grey"
        
        should_be_or_list list[1] do |or_list|
            or_list.length.should == 2
            should_be_term or_list[0], "big"
            should_be_term or_list[1], "small"         
        end
        
        should_be_term list[2], "tail"
      end      
    end
    
    it "should parse AND'd lists" do      
      should_be_and_list parse_one_element("(foo bar one AND two) AND (three four ten OR twelve)") do |list|                
        list.length.should == 2        
        
        should_be_list(list[0]) do |first_half|
          first_half[0].value.should == 'foo'
          first_half[1].value.should == "bar"
          should_be_and_list(first_half[2])          
        end
        
        should_be_list(list[1]) do |second_half|
          second_half[0].value.should == "three"
          second_half[1].value.should == "four"
          should_be_or_list second_half[2]          
        end
      end
    end
    
    it "should build for a crazy complicated one" do
      should_be_list parse("mark +twain AND huck OR fun OR ((jim AND river) AND (red -dogs))") do |list|
        should_be_term list[0], "mark"
        should_be_and_list list[1] do |and_list|
          
          should_be_mandatory and_list[0] do |operand|
            should_be_term operand, "twain"
          end
                                        
          should_be_or_list and_list[1] do |or_list|
            should_be_term or_list[0], "huck"
            should_be_term or_list[1], "fun"
            
            should_be_and_list or_list[2] do |and_list|
              and_list.length.should == 2
              
              should_be_and_list and_list[0]
              
              should_be_list and_list[1] do |terms|
                should_be_term terms[0], "red"
                should_be_excluded terms[1] do |operand|
                  should_be_term operand, "dogs"
                end
              end
            end
            
          end
        end
      end
    end
    
  end
end


