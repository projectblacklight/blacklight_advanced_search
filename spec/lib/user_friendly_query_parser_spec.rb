require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
def query(str)
  {"author"=> str,"title"=>str, :op => "AND"}
end

def config
  BlacklightAdvancedSearch.config[:advanced]
end
describe "BlacklightAdvancedSearch::UserFriendlyQueryParser" do
  include BlacklightAdvancedSearch::UserFriendlyQueryParser
  describe "User Friendly Queries" do
    it "should display the appropriate text for use in the UI" do
      process_friendly(query("(mouse AND dog) OR cat"),config)[:q][0][0].should == "Title = ((mouse AND dog) OR cat)" and 
      process_friendly(query("(mouse AND dog) OR cat"),config)[:q][1][0].should == "Author = ((mouse AND dog) OR cat)"
    end
    it "should process the filters appropriately for the UI" do
      process_friendly({:fq => {"location" => {"Online" => "1", "Library" => "1", "My House" => "2"}}},config)[:fq][0].should match(/Location = (Online|Library) OR (Online|Library) AND My House/) and
      process_friendly({:fq => {"location" => {"Online" => "1", "Library" => "1", "My House" => "1"}}},config)[:fq][0].should match(/Location = (Online|Library|My House) OR (Online|Library|My House) OR (Online|Library|My House)/)
    end
  end
end