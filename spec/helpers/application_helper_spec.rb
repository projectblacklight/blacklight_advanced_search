require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
# adding in this method so that we can test linking w/o the need for routing
def catalog_index_path(params)
  ""
end

def config
  BlacklightAdvancedSearch.config[:advanced]
end

describe ApplicationHelper do
  include ApplicationHelper
  describe "facet in params?" do
    it "should process the format facet parameter correctly for regular search" do
      params[:field] = "not_#{config[:search_field]}"
      params[:f] = {"format" => ["book"]} 
      facet_in_params?("format","book").should be_true
    end
    it "should process the format facet parameter correctly for advanced search" do
      params[:search_field] = config[:seach_field]
      params[:fq] = {"format_facet" => {"book"=>1}} 
      facet_in_params?("format_facet","book").should be_true
    end
  end
  
  describe "link to previous search" do
    before(:all) do
      Blacklight.stub(:config).and_return({:facet=>{:labels=>{"format_facet"=>"Format"}}})
      Blacklight.stub(:label_for_search_field).and_return("Author")
      Blacklight.stub(:default_search_field).and_return({:key=>"not_#{config[:search_field]}"})
      @regular_search_link = link_to_previous_search({:search_field=>"not_#{config[:search_field]}",
                                                      :q=>"My Query String",
                                                      :f=>{"format_facet"=>["Book"]}})
                                        
      @non_default_search_link = link_to_previous_search({:search_field=>"author",
                                                          :q=>"My Author Query String",
                                                          :f=>{"format_facet"=>["Book"]}})
                                                      
      @advanced_search_link = link_to_previous_search({:search_field=>config[:search_field],
                                                       :title=>"Record Title",
                                                       :author=>"Record Author",
                                                       :fq=>{"format_facet"=>{"Book"=>1,"Video"=>1}}})
    end
    describe "advanced search links" do
      it "should process the filters appropriately for advanced searches" do
        @advanced_search_link.should match(/\{Format = (Book|Video) OR (Video|Book)\}/)
      end
      it "should process the query strings appropriately for advanced searches" do
        @advanced_search_link.should match(/Title = \(Record Title\)/) and
        @advanced_search_link.should match(/Author = \(Record Author\)/)
      end
    end
    describe "normal search links" do
      it "should process the filters appropriately" do
        @regular_search_link.should match(/\{Format:Book\}/)
      end
      it "should process the query string appropriately" do
        @regular_search_link.should match(/>My Query String.*<\/a>/)
      end
      it "should process the query appropriately when the search type is not the default" do
        @non_default_search_link.should match(/Author\:\(My Author Query String\)/)
      end
    end  
  end
  
  describe "remove advanced query params" do
    it "should remove the correct advanced search params" do
      remove_advanced_query_params("title=Hello", {:title=>"Hello",:author=>"Somebody"}).should == {:author=>"Somebody"}
    end
  end
  
  describe "remove facet params" do
    it "should remove the facet params when they are of the advanced search style (fq)" do
      remove_facet_params(:format_facet,"Book",{:fq=>{"format_facet"=>{"Book"=>1}}})[:fq].should == {}
    end
  end
  
end