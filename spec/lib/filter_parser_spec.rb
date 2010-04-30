require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "BlacklightAdvancedSearch::FilterParser" do
  include BlacklightAdvancedSearch::FilterParser
  describe "filter processing" do
    it "should generate an appropriate fq param" do
      process_filters({:fq => {"location" => {"Online" => 1, "Library" => 1}, "format" => {"Book" => 1, "Thesis" => 1}}}).should match(/format\:\((\"Book\"|\"Thesis\") OR (\"Thesis\"|\"Book\")\), location\:\((\"Library\"|\"Online\") OR (\"Online\"|\"Library\")\)/)
    end
    it "should AND facets that are selected from the Refine section (those with a value of 2)" do
      process_filters({:fq => {"location" => {"Online" => "1", "Library" => "1", "My House" => "2"}}}).should match(/location\:\((\"Online\"|\"Library\") OR (\"Library\"|\"Online\") AND \"My House\"\)/)
    end
  end
end