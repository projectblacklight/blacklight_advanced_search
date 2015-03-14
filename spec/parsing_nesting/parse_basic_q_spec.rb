require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "NestingParser" do

  # Our ParseBasicQ mixin assumes a SolrHelper context. 
  # SolrHelper is a controller layer mixin, which depends
  # on being mixed into a class which has #params (from Rails)
  # and #blacklight_config
  #
  # This technique of testing is copied from Blacklight solr_helper_spec.rb
  #
  # It gets kind of a mess of dependencies, sorry. 
  class ParseBasicQTestClass
    cattr_accessor :blacklight_config

    include Blacklight::SearchHelper
    
    include BlacklightAdvancedSearch::ParseBasicQ


    def initialize blacklight_config
      self.blacklight_config = blacklight_config
    end

    def params
      {}
    end

    def logger
      Rails.logger
    end
  end

  describe "basic functionality" do
    before do
      @blacklight_config = Blacklight::Configuration.new do |config|
        config.advanced_search = {

        }

        config.add_search_field "all_fields" do |field|
          
        end

        config.add_search_field "special_field" do |field|
          field.advanced_parse = false
        end
      end
      @obj = ParseBasicQTestClass.new @blacklight_config 
    end

    it "catches a simple example" do
      expect(Deprecation).to receive(:warn)
      solr_params = {}
      @obj.add_advanced_parse_q_to_solr(solr_params, :q => "one two AND three OR four") 

      expect(solr_params[:defType]).to eq("lucene")
      # We're not testing succesful parsing here, just that it's doing
      # something that looks like we expect with subqueries. 
      expect(solr_params[:q]).to start_with("_query_:")
    end

    it "passes through an unparseable example" do
      expect(Deprecation).to receive(:warn)
      solr_params = {}
      unparseable_q = "foo bar\'s AND"
      @obj.add_advanced_parse_q_to_solr(solr_params, :q => unparseable_q)

      expect(solr_params[:q]).to eq(unparseable_q)
    end

    it "ignores field with advanced_parse=false" do
      expect(Deprecation).to receive(:warn)
      solr_params = {}
      original_q = "one two AND three OR four"
      @obj.add_advanced_parse_q_to_solr(solr_params, 
        :search_field => "special_field",
        :q => original_q
      )

      expect(solr_params).not_to have_key(:q)
    end

  end
  
end