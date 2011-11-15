class AdvancedController < BlacklightAdvancedSearch::AdvancedController

  blacklight_config.configure do |config|
    config.advanced_search.form_solr_parameters ||= {}
    config.advanced_search.url_key ||= 'advanced'
  end

end
