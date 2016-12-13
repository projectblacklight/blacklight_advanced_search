describe BlacklightAdvancedSearch::AdvancedSearchBuilder do
  describe "#add_advanced_parse_q_to_solr" do
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.advanced_search = {}
        config.add_search_field "all_fields"
        config.add_search_field "special_field" do |field|
          field.advanced_parse = false
        end
      end
    end

    let(:obj) do
      class BACTestClass
        cattr_accessor :blacklight_config, :blacklight_params
        include Blacklight::SearchHelper
        include BlacklightAdvancedSearch::AdvancedSearchBuilder
        def initialize(blacklight_config, blacklight_params)
          self.blacklight_config = blacklight_config
          self.blacklight_params = blacklight_params
        end
      end
      BACTestClass.new blacklight_config, params
    end

    context "with basic functionality" do
      let(:solr_params) { {} }

      describe "a simple example" do
        let(:params) { { :q => "one two AND three OR four" } }
        it "catches the query" do
          obj.add_advanced_parse_q_to_solr(solr_params)
          expect(solr_params[:defType]).to eq("lucene")
          # We're not testing succesful parsing here, just that it's doing
          # something that looks like we expect with subqueries.
          expect(solr_params[:q]).to start_with("_query_:")
        end
      end

      describe "an unparseable example" do
        let(:unparseable_q) { "foo bar\'s AND" }
        let(:params) { { :q => unparseable_q } }
        it "passes through" do
          obj.add_advanced_parse_q_to_solr(solr_params)
          expect(solr_params[:q]).to eq(unparseable_q)
        end
      end

      context "when advanced_parse is false" do
        let(:params) { { :search_field => "special_field", :q => "one two AND three OR four" } }
        it "ignores fields" do
          obj.add_advanced_parse_q_to_solr(solr_params)
          expect(solr_params).not_to have_key(:q)
        end
      end
    end
  end
end
