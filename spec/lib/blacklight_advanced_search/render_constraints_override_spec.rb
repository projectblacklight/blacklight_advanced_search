describe BlacklightAdvancedSearch::RenderConstraintsOverride, type: :helper do
  let(:blacklight_config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'type'
    end
  end

  let(:advanced_query) do
    BlacklightAdvancedSearch::QueryParser.new(params, blacklight_config)
  end
end
