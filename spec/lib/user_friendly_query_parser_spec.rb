require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
def build_query(str)
  {"author"=> str,"title"=>str, :op => "AND"}
end

def config
  BlacklightAdvancedSearch.config[:advanced]
end
describe "UserFriendlyQueryParser" do
  it "should display the appropriate text for use in the UI" do
    query = BlacklightAdvancedSearch::UserFriendlyQueryParser.new(build_query("(mouse AND dog) OR cat"),config)
    query.author.should == "Author = ((mouse AND dog) OR cat)"
    query.title.should == "Title = ((mouse AND dog) OR cat)"
  end
  it "should return the correct methods when for matching hash keys" do
    query = BlacklightAdvancedSearch::UserFriendlyQueryParser.new(build_query("(mouse AND dog) OR cat"),config)
    query.author.should == "Author = ((mouse AND dog) OR cat)"
    query.title.should == "Title = ((mouse AND dog) OR cat)"
  end
  it "should process the facets appropriately for the UI" do
    query = BlacklightAdvancedSearch::UserFriendlyQueryParser.new({:fq => {"location" => {"Online" => "1", "Library" => "1", "My House" => "2"}}},config)
    query.facets.length.should == 1
    query.facets.first[:and].should == ["My House"]
    query.facets.first[:or].should == ["Online","Library"]
    query.facets.first[:field].should == "location"
  end
  it "should provide a working each method" do
    query = BlacklightAdvancedSearch::UserFriendlyQueryParser.new(build_query("(mouse AND dog) OR cat"),config)
    hsh = {}
    query.each do |key,value|
      hsh[key] = value
    end
    hsh.has_key?(:author).should be_true and
    hsh[:author].should == "Author = ((mouse AND dog) OR cat)"
    hsh.has_key?(:title).should be_true and
    hsh[:title].should == "Title = ((mouse AND dog) OR cat)"
  end
  
end