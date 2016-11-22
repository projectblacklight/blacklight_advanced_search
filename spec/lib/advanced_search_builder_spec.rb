describe BlacklightAdvancedSearch::AdvancedSearchBuilder do
  let(:url_key) { 'advanced' }
  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.advanced_search = { url_key: 'advanced' }
      config.add_search_field "all_fields"
      config.add_search_field "special_field" do |field|
        field.advanced_parse = false
      end
    end
  end
  let!(:obj) do
    class BACTestClass
      cattr_accessor :blacklight_config
      include Blacklight::SearchHelper
      include BlacklightAdvancedSearch::AdvancedSearchBuilder
      def initialize(blacklight_config)
        self.blacklight_config = blacklight_config
      end
    end
    BACTestClass.new blacklight_config
  end

  describe "#add_advanced_parse_q_to_solr" do
    context "with basic functionality" do
      let(:solr_params) { {} }

      describe "a simple example" do
        let(:params) { double("params", params: { :q => "one two AND three OR four" }) }
        before { allow(obj).to receive(:scope).and_return(params) }
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
        let(:params) { double("params", params: { :q => unparseable_q }) }
        before { allow(obj).to receive(:scope).and_return(params) }
        it "passes through" do
          obj.add_advanced_parse_q_to_solr(solr_params)
          expect(solr_params[:q]).to eq(unparseable_q)
        end
      end

      context "when advanced_parse is false" do
        let(:params) { double("params", params: { :search_field => "special_field", :q => "one two AND three OR four" }) }
        before { allow(obj).to receive(:scope).and_return(params) }
        it "ignores fields" do
          obj.add_advanced_parse_q_to_solr(solr_params)
          expect(solr_params).not_to have_key(:q)
        end
      end
    end
  end

  describe "#add_advanced_search_to_solr" do
    let(:to_solr) { { q: 'advanced query', fq: 'inclusive facet' } }
    let(:advanced_query) { double('advanced_query') }
    let(:solr_params) { { q: 'basic', fq: 'original fq' } }
    before do
      allow(advanced_query).to receive(:to_solr).and_return(to_solr)
      allow(advanced_query).to receive(:keyword_queries).and_return([])
      allow(BlacklightAdvancedSearch::QueryParser).to receive(:new).and_return(advanced_query)
      allow(obj).to receive(:blacklight_params).and_return(blacklight_params)
      obj.add_advanced_search_to_solr(solr_params)
    end

    context "with advanced search_field param and facet" do
      let(:blacklight_params) do
        { f_inclusive: { language_facet: ['English'] }, search_field: url_key }
      end
      it 'updates solr_params with advanced q' do
        expect(solr_params[:q]).to eq('advanced query')
      end
      it 'updates solr_params with advanced fq' do
        expect(solr_params[:fq]).to eq('inclusive facet')
      end
    end

    context "with basic search_field param and advanced facet" do
      let(:blacklight_params) do
        { f_inclusive: { language_facet: ['English'] }, search_field: 'all_fields' }
      end
      it 'solr_params q remains the same' do
        expect(solr_params[:q]).to eq('basic')
      end
      it 'updates solr_params with advanced fq' do
        expect(solr_params[:fq]).to eq('inclusive facet')
      end
    end
  end
end
