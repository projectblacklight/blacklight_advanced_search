# frozen_string_literal: true

describe AdvancedHelper do
  describe '#advanced_search_facet_partial_name' do
    let(:field) { double(name: 'field_name') }

    it 'returns the configured partial name if present' do
      expect(helper).to receive(:facet_configuration_for_field).with(field.name).and_return(double(partial: 'partial-name'))
      expect(helper.advanced_search_facet_partial_name(field)).to eq 'partial-name'
    end

    it 'fallbacks on "catalog/facet_limit" in the absence of a configured partial' do
      expect(helper).to receive(:facet_configuration_for_field).with(field.name).and_return(nil)
      expect(helper.advanced_search_facet_partial_name(field)).to eq 'catalog/facet_limit'
    end
  end
end
