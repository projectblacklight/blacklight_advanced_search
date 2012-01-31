class AdvancedController < BlacklightAdvancedSearch::AdvancedController

  copy_blacklight_config_from(CatalogController)

  blacklight_config.configure do |config|
    config.advanced_search.form_solr_parameters ||= {}
    config.advanced_search.url_key ||= 'advanced'
  end

end
