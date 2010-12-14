require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def setQuery(str)
  @query = {"author"=> str,"title"=>str}
end

BlacklightAdvancedSearch.config.merge!( 
  {:search_fields => 
    [
      {:key => "author", :solr_local_parameters => {
          :qf => "$qf_author",
          :pf => "$pf_author"}
      },
      {:key=> "title", :solr_local_parameters => {
          :qf => "$qf_title",
          :pf => "$pf_title"}
      }
    ]
  })
def config
  BlacklightAdvancedSearch.config
end

def keyword_queries
  @query
end

def keyword_op
  "AND"
end

describe "BlacklightAdvancedSearch::DismaxQueryParser" do
  include BlacklightAdvancedSearch::DismaxQueryParser
  
  
  describe "'AND' processing" do
    it "should remove all parens and 'AND's then append every word with a '+' if there are no other boolean operators present" do
      setQuery "hello AND goodbye"
      process_query(nil,config).should match(/\}\+hello \+goodbye\"/)

      setQuery "((dog cat) AND mouse) AND house"
      process_query(nil,config).should match(/\}\+dog \+cat \+mouse \+house\"/)

      setQuery "(dog AND cat) house AND (mouse OR rat)"
      process_query(nil,config).should match(/\}\+\(\+dog \+cat\) \+house \+\(mouse OR rat\)\"/)
    end
  
    it "should process implied and implicit ANDs between parenthetical statements correctly and equally" do
      setQuery("(lesbian OR gay) (book OR video)")    
      first = process_query(nil ,config)

      setQuery("(lesbian OR gay) AND (book OR video)")
      second = process_query(nil, config)
            
      first.should match(/\}\+\(lesbian OR gay\) \+\(book OR video\)\"/)
      first.should == second
    end
    it "should process implied ANDs when only words are provided in the middle of parenthetical statements" do
      setQuery("(hello OR goodbye) mouse (aloha AND aloha2)")
    
      process_query(nil,config).should match(/\}\+\(hello OR goodbye\) \+mouse \+\(\+aloha \+aloha2\)\"/)
    end
    it "should not apply additional '+' signs to words that already have them" do
      setQuery("+hello +goodbye OR something")
      process_query(nil,config).should match(/\}\+hello \+goodbye\ OR something/)
    end
    it "should not apply a '+' sign if the first character is a '-'" do
      setQuery("(goodbye AND -hello) OR something")
      process_query(nil,config).should match(/\}\(\+goodbye -hello\) OR something\"/)
    end
  end
  
  describe "'OR' processing" do
    it "should leave queries with only ORs alone" do
      setQuery "evgeni OR nabokov"
      process_query(nil,config).should match(/\}evgeni OR nabokov\"/)
    end
  end
  
  describe "'NOT' processing" do
    it "should not put a '+' in front of a word preceded by a NOT in an ANDed query" do
      setQuery "(dog AND cat) NOT mouse"    
      process_query(nil,config).should match(/\}\(\+dog \+cat\) NOT mouse\"/)

      setQuery "dog AND cat NOT mouse"
      process_query(nil,config).should match(/\}\(\+dog \+cat\) NOT mouse\"/)
    end
    it "should handle a query with only the NOT boolean correctly" do
      setQuery "cat NOT mouse"
      process_query(nil,config).should match(/\}\+cat NOT mouse\"/)
    end
    it "should handle a query with only the NOT boolean and several terms correctly" do
      setQuery "NOT mouse cat dog"
      process_query(nil,config).should match(/\}NOT mouse \+cat \+dog\"/)

      setQuery "cat NOT mouse dog"
      process_query(nil,config).should match(/\}\+cat NOT mouse \+dog\"/)
    end
    it "should build a add NOT to the beginning of a solr Query if the there are 2 words and the first is NOT" do
      setQuery "NOT hat"
      process_query(nil,config).should match(/^NOT _query/)
      
      setQuery "NOT house mouse"
      process_query(nil,config).should_not match(/^NOT _query/)
    end
    it "should handle items with ANDs and NOTs correctly" do
      setQuery "((apple AND horn) OR (orange AND piano)) AND hello NOT goodbye"
      process_query(nil,config).should match(/\}\+\(\(\+apple \+horn\) OR \(\+orange \+piano\)\) \+hello NOT goodbye\"/)

      setQuery "(aloha AND hello NOT goodbye) AND (something AND something2 else)"
      process_query(nil,config).should match(/\}\+\(\+aloha \+hello NOT goodbye\) \+\(\+something \+something2 \+else\)\"/)
    end
    it "should handle items with AND and NOT between parens correctly" do
      setQuery "(klezmer OR accordion) NOT russian AND (score OR recording)"
      process_query(nil,config).should match(/\}\+\(klezmer OR accordion\) NOT russian \+\(score OR recording\)\"/)
    end
  end
  
  describe "plain query processing" do
    it "should deal with plain queries normally" do
      setQuery "evgeni nabokov"
      process_query(nil,config).should match(/\}\+evgeni \+nabokov\"/)

      setQuery "black and tan"
      process_query(nil,config).should match(/\}\+black \+and \+tan\"/)
    end
  end
  
  describe "parenthesis processing" do
    it "should insert the implicit parens (L2R) for queries w/ different boolean operators and no user entered parens" do

      setQuery "dog AND cat OR mouse"
      process_query(nil,config).should match(/\}\(\+dog \+cat\) OR mouse\"/)

      setQuery "mouse OR cat AND dog"
      process_query(nil,config).should match(/\}\+\(mouse OR cat\) \+dog\"/)
    end
    it "should handle nested parenthesis properly (including extra parens)" do
      setQuery "((dog OR cat) AND (mouse AND bug)) house"    
      process_query(nil,config).should match(/\}\+\(\+\(dog OR cat\) \+\(\+mouse \+bug\)\) \+house\"/)

      setQuery "(((dog AND cat) OR (mouse AND bug)) OR house)"
      process_query(nil,config).should match(/\}\(\(\(\+dog \+cat\) OR \(\+mouse \+bug\)\) OR house\)\"/)
    end
  end
  
  describe "full Solr query" do
    it "should generate a valid Solr query as per the specification" do
      setQuery "(apple OR orange) AND bobbing"
      
      # Kind of hacky stuff to semi sort of parse the solr query to test it,
      # instead of assuming an exact string. Since order can be different on
      # different systems, and does not matter for meaning. 
      solr_query = process_query(nil,config)
      
      clauses = solr_query.split( / +AND +/ )
      
      clauses.find do |clause|
        clause =~ /^_query_:\"\{\!dismax mm=1 (qf=\$qf_title|pf=\$pf_title) (pf=\$pf_title|qf=\$qf_title)\}\+\(apple OR orange\) \+bobbing\"/
      end.should_not be_nil
      
      clauses.find do |clause|
        clause =~ /^_query_:\"\{\!dismax mm=1 (qf=\$qf_author|pf=\$pf_author) (pf=\$pf_author|qf=\$qf_author)\}\+\(apple OR orange\) \+bobbing\"/
      end.should_not be_nil
                  
    end
  end
  
end