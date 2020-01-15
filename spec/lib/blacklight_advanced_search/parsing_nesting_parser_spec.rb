# frozen_string_literal: true

describe BlacklightAdvancedSearch::ParsingNestingParser, type: :module do
  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'type'
    end
  end

  let(:subject) { Object.new.extend(described_class) }

  describe '#local_param_hash' do
    context 'with config[key] being nil' do
      let(:key) { 'foo' }

      it 'does not fail do no nil error' do
        expect { subject.local_param_hash(key, blacklight_config) }.not_to raise_error
      end
    end
  end
end
