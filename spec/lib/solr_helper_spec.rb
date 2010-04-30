require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
def solr_search_params(extra_controller_params={})
  extra_controller_params
end

def solr_docs
  [{:id=>"1",:title=>"Title1",:author=>"Author1"},
   {:id=>"2",:title=>"Title2",:author=>"Author2"},
   {:id=>"3",:title=>"Title3",:author=>"Author3"}
    ]
end

describe "BlacklightAdvancedSearch::SolrHelper" do
  include BlacklightAdvancedSearch::SolrHelper
  describe "get single doc via search" do
    before(:each) do
      Blacklight = stub("mock_object")
      Blacklight.stub(:solr).and_return({})
      Blacklight.solr.stub(:find).and_return({})
      Blacklight.solr.find.stub(:docs).and_return(solr_docs)
    end
    it "should get an advanced query when the localized solr_params show an advanced search" do
      get_single_doc_via_search({:qt=>BlacklightAdvancedSearch.config[:advanced][:search_field]})[:id].should == "1" and
      @advanced_query.should_not be_nil
    end
    it "should not get an advanced query when the localized solr_params do not show an advanced search" do
      get_single_doc_via_search({:qt=>"non_advanced_search_qt"})[:id].should == "1" and
      @advanced_query.should be_nil
    end
  end
  
end
