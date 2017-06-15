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

    let(:params) { {} }

    describe '#is_advanced_search?' do
      context 'without the advanced search plugin configured' do
        let(:blacklight_config) { Blacklight::Configuration.new }

        it 'is false' do
          expect(obj.is_advanced_search?).to be_falsey
        end
      end
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

        describe 'when parslet fails' do
          let(:failing_q) { ")(" }
          let(:params) { { :q => failing_q } }
          it 'does not return the query that could not be parsed' do
            obj.add_advanced_parse_q_to_solr(solr_params)
            expect(solr_params[:q]).to be_nil
          end
        end

        describe 'when `q` is a hash' do
          let(:params) { { q: { id: ['a'] } } }
          it 'does not return the query that could not be parsed' do
            obj.add_advanced_parse_q_to_solr(solr_params)
            expect(solr_params[:q]).to be_nil
          end
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
