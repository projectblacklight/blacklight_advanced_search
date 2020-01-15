# frozen_string_literal: true

describe BlacklightAdvancedSearch::RenderConstraintsOverride, type: :helper do
  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'type'
    end
  end

  let(:advanced_query) do
    BlacklightAdvancedSearch::QueryParser.new(params, blacklight_config)
  end

  describe '#render_constraints_filters' do
    subject(:rendered) { helper.render_constraints_filters({}) }

    before do
      allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
      allow(helper).to receive(:advanced_query).and_return(advanced_query)
      allow(helper).to receive(:search_action_path) do |*args|
        search_catalog_path(*args)
      end
    end

    context 'with an array of facet params' do
      let(:params) { ActionController::Parameters.new f_inclusive: { 'type' => ['a'] } }

      it 'renders nothing' do
        expect(rendered).to have_text 'Remove constraint Type: a'
      end
    end

    context 'with scalar facet limit params' do
      let(:params) { ActionController::Parameters.new f_inclusive: { 'type' => 'a' } }

      it 'renders the scalar value' do
        expect(rendered).to have_text 'Remove constraint Type: a'
      end
    end
  end
end
