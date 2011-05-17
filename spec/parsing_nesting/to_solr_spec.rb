require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
#require 'rubygems'
#require 'parslet'
#require 'spec'
#require 'spec/autorun'

#load '../../lib/parsing_nesting/grammar.rb'
#load '../../lib/parsing_nesting/tree.rb'

module SolrQuerySpecHelper
  def parse(s)
    ParsingNesting::Tree.parse(s)
  end
  
  # yields localparam string, and the actual internal query
  def local_param_match(query)
    query.should =~ /^ *_query_:\"\{([^}]+)\}(.*)" *$/
    query =~ /^ *_query_:\"\{([^}]+)\}(.*)" *$/
    (param_str = $1).should_not be_nil
    (query = $2).should_not be_nil
    
    yield [param_str, query] if block_given?
  end
  
  def bare_local_param_match(query)
    query.should =~ / *\{([^}]+)\}(.*)/
    query =~ /\{([^}]+)\}(.*)/
    (param_str = $1).should_not be_nil
    (query = $2).should_not be_nil
    yield [param_str, query] if block_given?
  end
  
  # Convenience for matching a lucene query combining nested queries,
  # and getting out the nested queries as matches. 
  # pass in a string representing a regexp that uses $QUERY as placeholder where
  # a nested _query_: will be. 
  #
  # * Any parens in your passed in regexp will
  # be paren literals, don't escape em yourself -- you can't do your
  # own captures, because if the regexp passes, it'll yield to a block
  # with a list, in order, of nested queries.
  #  
  #
  # * Can include $ALL to represent literal "*:*"
  #
  # Yes, the regexp matching isn't as robust as it could be, hard
  # to deal with like escaped end-quotes and stuff in a regexp, but
  # should mostly work.   
  def query_template_matcher(top_query, regexp_str)
    nested_re = '(_query_:".+")'
    regexp_str = regexp_str.gsub("(", '\(').gsub(')', '\)').gsub("$QUERY", nested_re).gsub("$ALL", "\\*\\:\\*")
    regexp = Regexp.new('^ *' + regexp_str + ' *$')

    top_query.should match( regexp )
    
    yield *regexp.match(top_query).captures if block_given?    
  end
end

describe "NestingParser" do
    describe "Translating to Solr" do
    include SolrQuerySpecHelper
       
    describe "with basic simple query" do
      before do
        @query = parse("one two three").to_query(:qf => "field field2^5", :pf=>"$pf_title")
      end
      
      it "should insist on dismax for nested query" do
        query = parse("one two three").to_query(:defType => "field", :qf=>"$qf")
        local_param_match(query) do |params, query|
          params.should match(/^\!dismax /)
          params.should_not match(/field/)
        end
      end
      
      it "should include LocalParams" do
        local_param_match(@query) do |params, query|
          params.should include("pf=$pf_title")
          params.should include('qf=\'field field2^5\'')          
        end                
      end
      
      it "should include the query" do
        local_param_match(@query) do |params, query|
          query.should == "one two three"
        end
      end
    end
    
    describe "with simple mandatory/excluded terms" do
      before do
        @inner_query = 'red +army -"soviet union" germany'
        @full_query = parse(@inner_query).to_query(:qf => "foo", :pf=>"bar")
      end
      it "should include query" do
        local_param_match(@full_query) do |params, query|
          query.should == @inner_query.gsub('"', '\\\\"')
        end
      end
    end
    
    describe "with embeddable AND query" do
      before do
        @query = parse("one two AND three").to_query({:qf => "$qf"})
      end
      it "should flatten to one dismax query" do
        local_param_match(@query) do |params, query|
          query.should == "one +two +three"
        end
      end
      
      describe ", with mandatory/excluded" do
        before do
          @query = parse("one -two AND +three").to_query({:qf=>"$qf"})
        end
        it "should preserve +/- operators" do
          local_param_match(@query) do |params, query|
            query.should == "one -two +three"
          end
        end
      end
      
      describe ", deeply nested" do
        before do
          @query = parse("blue (green AND -violet) AND (+big AND (-small AND medium))").to_query({:qf=>"$qf"})
        end
        it "should flatten into dismax" do
          local_param_match(@query) do |params, query|
            query.should == "blue +green -violet +big -small +medium"
          end
        end
      end     
      
      it "for simple OR list, forcing mm=1" do
        query = parse("one OR two OR three").to_query(:qf => "$qf", :mm=>"50%")        
        local_param_match(query) do |params, query|
          params.should include("mm=1")
          query.should == "one two three"
        end                
      end
    end
   
    
    describe "that needs to create multiple nested queries" do

      
      it "for two lists, OR'd" do
        query = parse("(one two three) OR (red -green +blue)").to_query(:qf => "$qf")  
        
        query_template_matcher(query, "( *$QUERY +OR +$QUERY *)" ) do |first_half, second_half|
                
          local_param_match(first_half) do |params, query|
            params.should include("qf=$qf")
            query.should == "one two three"
          end
          
          local_param_match(second_half) do |params, query|
            params.should include("qf=$qf")
            query.should == "red -green +blue"
          end
        end
      end
      
      it "for AND list that can not be flattened" do
        params = {:qf=>"$qf", :pf=>"$pf", :mm=>"50%"}
        query = parse("a OR b AND x OR y").to_query( params )
        
        query_template_matcher(query, "( *$QUERY +AND +$QUERY *)" ) do |first, second|                
          first.should == parse("a OR b").to_query(params)
          second.should == parse("x OR y").to_query(params)
        end
      end
      
      it "for AND of two lists" do
        params = {:qf => "$qf", :pf=>"$pf", :mm=>"50%"}
        query = parse("(one +two three) AND (four five -six)").to_query( params )
                
        query_template_matcher(query, "( *$QUERY +AND +$QUERY *)" ) do |first, second|
          first.should == parse("one +two three").to_query(params)
          second.should == parse("four five -six").to_query(params)          
        end
                
      end
      
      it "for crazy complicated query" do
        query = parse("red AND dawn OR (-night -afternoon) AND NOT (moscow OR beach) ").to_query(:qf => "$qf", :pf =>"$pf", :mm=>"50%")
        
        query_template_matcher(query, "( *$QUERY +AND +( *$QUERY +OR +($ALL AND NOT $QUERY *) *) +AND NOT $QUERY *)") do |red_q, dawn_q, night_q, moscow_q|
        
          local_param_match(red_q) { |params, query| query.should == "red" }            
        
          local_param_match(dawn_q) { |params, query| query.should == "dawn"}
          
          local_param_match(night_q) do |params, query|
            params.should include("mm=1")
            query.should == "night afternoon"
          end
          
          local_param_match(moscow_q) do |params, query|
            params.should include("mm=1")
            query.should == "moscow beach"
          end
        
        end
                
      end
      
      
    end
    
    describe "for NOT operator" do
      it "simple" do
        query = parse("NOT frog").to_query
          
        query_template_matcher(query, "NOT $QUERY") do |q|
          q.should == parse("frog").to_query
        end                    
      end
      it "binds tightly" do
        query = parse("one NOT two three").to_query
       
        query_template_matcher(query, "$QUERY AND NOT $QUERY") do |q1, q2|
          
          local_param_match(q1) do |params, query|
            query.should == "one three"
          end
          
          local_param_match(q2) do |params, query|
            query.should == "two"
          end
        end
        
      end
      it "complicated operand" do
        query = parse("one OR two NOT (three OR four AND five)").to_query
        #"_query_:'{!dismax mm=1}one two' AND NOT ( _query_:'{!dismax mm=1}three four' AND _query_:'{!dismax }five' )"
        query_template_matcher(query, "$QUERY +AND NOT +( *$QUERY +AND +$QUERY *)") do |external_or, internal_or, internal_term|
          external_or.should == parse("one OR two").to_query
          internal_or.should == parse("three OR four").to_query 
          internal_term.should == parse("five").to_query 
        end        
      end
      
      it "uses workaround on NOT as operand to OR" do
        query = parse("two OR (NOT (three))").to_query
        query_template_matcher(query, "( *$QUERY +OR +($ALL +AND +NOT +$QUERY) *)")        
      end
      
    end
    
    describe "for pure negative" do
      it "should convert simple pure negative" do
        query = parse('-one -two -"a phrase"').to_query(:qf => "$qf", :mm => "100%")
        
        query_template_matcher(query, " *NOT $QUERY") do |query|
          local_param_match(query) do |params, query|
            params.should include("mm=1")
            query.should == 'one two \\"a phrase\\"'
          end
        end
        
      end
      
      it "should convert pure negative AND" do
        query = parse("-one AND -two AND -three").to_query(:qf => "$qf", :mm => "100%")
        
        query_template_matcher(query, "NOT $QUERY") do |query|
          local_param_match(query) do |params, query|
            params.should =~ /mm=1 |$/
            query.should == 'one two three'
          end
        end
      end
      
      it "should convert pure negative OR" do
        query = parse("-one OR -two OR -three").to_query        
        
        query_template_matcher(query, "NOT $QUERY") do |query|
          local_param_match(query) do |params, query|
            params.should include("mm=100%")
            query.should == "one two three"
          end
        end

      end
      
      it "should convert crazy pure negative combo" do        
        query = parse("(-one -two) OR -three OR (-five AND -six)").to_query
        
        query_template_matcher(query, "( *($ALL +AND +NOT +$QUERY) +OR +( *$ALL +AND +NOT +$QUERY *) +OR +( *$ALL +AND +NOT +$QUERY *) *)")                
      end
    end
    
    
    # When a single parse will be the whole query, we use
    # different more compact production
    describe "Single Query" do
      before do
        @solr_local_params = {"qf" => "$title_qf", "pf" => "$title_pf"}
      end
      describe "simple search" do
        it "should work with local params" do
          hash = parse("one +two -three").to_single_query_params(@solr_local_params)
          hash[:defType].should == "dismax"
          bare_local_param_match(hash[:q]) do |params, query|
            query.should == "one +two -three"
            params.should include("pf=$title_pf")
            params.should include("qf=$title_qf")
          end
        end
        
        it "should work without local params" do
          hash = parse("one +two -three").to_single_query_params({})
          hash[:defType].should == "dismax"
          hash[:q].should == "one +two -three"          
        end
      end
      describe "simple pure negative" do
        it "should be nested NOT" do
          hash = parse("-one -two").to_single_query_params({})
          hash[:defType].should == "dismax"
          query_template_matcher(hash[:q], "NOT $QUERY") do |query|
            local_param_match(query) do |params, query|
              query.should == "one two"
              params.should include("mm=1")
            end            
          end
        end
      end
      describe "complex query" do
        it "should parse" do
          hash = parse("one AND (two OR three)").to_single_query_params({})
          hash[:defType].should == "lucene"
          query_template_matcher(hash[:q], "( *$QUERY +AND +$QUERY *)") do |first, second|
            local_param_match(first) do |params, query|
              params.should include("dismax")
              query.should == "one"
            end
            local_param_match(second) do |params, query|
              params.should include("mm=1")
              params.should include("dismax")
              query.should == "two three"
            end
          end
        end
      end
      
      
    end  

    
  end
  
  
  
  
end


