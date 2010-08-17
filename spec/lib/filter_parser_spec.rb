require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def setFilters(f)
  @filters = f
end

def filters
  @filters
end


describe "BlacklightAdvancedSearch::FilterParser" do
  include BlacklightAdvancedSearch::FilterParser
  
  describe "filter processing" do
    it "should generate an appropriate fq param" do
      setFilters(:format => ["Book", "Thesis"], :location=>["Online", "Library"])

      fq_params = generate_solr_fq

      fq_params.find {|a| a =~ /format\:\((\"Book\"|\"Thesis\") +OR +(\"Thesis\"|\"Book\")/}.should_not be_nil

      fq_params.find {|a| a =~ /location\:\((\"Library\"|\"Online\") +OR +(\"Library\"|\"Online\")/}.should_not be_nil
      

    end    
  end
end