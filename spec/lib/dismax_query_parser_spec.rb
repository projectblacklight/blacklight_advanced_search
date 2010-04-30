require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def query(str)
  {"author"=> str,"title"=>str, :op => "AND"}
end

def config
  BlacklightAdvancedSearch.config[:advanced]
end

describe "BlacklightAdvancedSearch::DismaxQueryParser" do
  include BlacklightAdvancedSearch::DismaxQueryParser
  describe "'AND' processing" do
    it "should remove all parens and 'AND's then append every word with a '+' if there are no other boolean operators present" do
      process_query(query("hello AND goodbye"),config).should match(/\}\+hello \+goodbye\"/) and
      process_query(query("((dog cat) AND mouse) AND house"),config).should match(/\}\+dog \+cat \+mouse \+house\"/) and
      process_query(query("(dog AND cat) house AND (mouse OR rat)"),config).should match(/\}\+\(\+dog \+cat\) \+house \+\(mouse OR rat\)\"/)
    end
    it "should process implied and implicit ANDs between parenthetical statements correctly and equally" do
      first_q = process_query(query("(lesbian OR gay) (book OR video)"),config)
      second_q = process_query(query("(lesbian OR gay) AND (book OR video)"),config)
      first_q.should match(/\}\+\(lesbian OR gay\) \+\(book OR video\)\"/) and first_q.should == second_q
    end
    it "should process implied ANDs when only words are provided in the middle of parenthetical statements" do
      process_query(query("(hello OR goodbye) mouse (aloha AND aloha2)"),config).should match(/\}\+\(hello OR goodbye\) \+mouse \+\(\+aloha \+aloha2\)\"/)
    end
    it "should not apply additional '+' signs to words that already have them" do
      process_query(query("+hello +goodbye OR something"),config).should match(/\}\+hello \+goodbye\ OR something"/)
    end
    it "should not apply a '+' sign if the first character is a '-'" do
      process_query(query("(goodbye AND -hello) OR something"),config).should match(/\}\(\+goodbye -hello\) OR something\"/)
    end
  end
  
  describe "'OR' processing" do
    it "should leave queries with only ORs alone" do
      process_query(query("evgeni OR nabokov"),config).should match(/\}evgeni OR nabokov\"/)
    end
  end
  
  describe "'NOT' processing" do
    it "should not put a '+' in front of a word preceded by a NOT in an ANDed query" do
      process_query(query("(dog AND cat) NOT mouse"),config).should match(/\}\(\+dog \+cat\) NOT mouse\"/) and
      process_query(query("dog AND cat NOT mouse"),config).should match(/\}\(\+dog \+cat\) NOT mouse\"/)
    end
    it "should handle a query with only the NOT boolean correctly" do
      process_query(query("cat NOT mouse"),config).should match(/\}\+cat NOT mouse\"/)
    end
    it "should handle a query with only the NOT boolean and several terms correctly" do
      process_query(query("NOT mouse cat dog"),config).should match(/\}NOT mouse \+cat \+dog\"/) and
      process_query(query("cat NOT mouse dog"),config).should match(/\}\+cat NOT mouse \+dog\"/)
    end
    it "should build a add NOT to the beginning of a solr Query if the there are 2 words and the first is NOT" do
      process_query(query("NOT hat"),config).should match(/^NOT _query/) and
      process_query(query("NOT house mouse"),config).should_not match(/^NOT _query/)
    end
    it "should handle items with ANDs and NOTs correctly" do
      process_query(query("((apple AND horn) OR (orange AND piano)) AND hello NOT goodbye"),config).should match(/\}\+\(\(\+apple \+horn\) OR \(\+orange \+piano\)\) \+hello NOT goodbye\"/) and
      process_query(query("(aloha AND hello NOT goodbye) AND (something AND something2 else)"),config).should match(/\}\+\(\+aloha \+hello NOT goodbye\) \+\(\+something \+something2 \+else\)\"/)
    end
    it "should handle items with AND and NOT between parens correctly" do
      process_query(query("(klezmer OR accordion) NOT russian AND (score OR recording)"),config).should match(/\}\+\(klezmer OR accordion\) NOT russian \+\(score OR recording\)\"/)
    end
  end
  
  describe "plain query processing" do
    it "should deal with plain queries normally" do
      process_query(query("evgeni nabokov"),config).should match(/\}\+evgeni \+nabokov\"/) and
      process_query(query("black and tan"),config).should match(/\}\+black \+and \+tan\"/)
    end
  end
  
  describe "parenthesis processing" do
    it "should insert the implicit parens (L2R) for queries w/ different boolean operators and no user entered parens" do
      process_query(query("dog AND cat OR mouse"),config).should match(/\}\(\+dog \+cat\) OR mouse\"/) and
      process_query(query("mouse OR cat AND dog"),config).should match(/\}\+\(mouse OR cat\) \+dog\"/)
    end
    it "should handle nested parenthesis properly (including extra parens)" do
      process_query(query("((dog OR cat) AND (mouse AND bug)) house"),config).should match(/\}\+\(\+\(dog OR cat\) \+\(\+mouse \+bug\)\) \+house\"/) and
      process_query(query("(((dog AND cat) OR (mouse AND bug)) OR house)"),config).should match(/\}\(\(\(\+dog \+cat\) OR \(\+mouse \+bug\)\) OR house\)\"/)
    end
  end
  
  describe "full Solr query" do
    it "should generate a valid Solr query as per the specification" do
      process_query(query("(apple OR orange) AND bobbing"),config).should match(/^_query_:\"\{\!dismax (qf=\$qf_title|pf=\$pf_title) (pf=\$pf_title|qf=\$qf_title) \}\+\(apple OR orange\) \+bobbing\" AND _query_:\"\{\!dismax (qf=\$qf_author|pf=\$pf_author) (pf=\$pf_author|qf=\$qf_author) \}\+\(apple OR orange\) \+bobbing\"/)
    end
  end
  
end