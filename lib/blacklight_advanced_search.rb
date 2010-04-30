module BlacklightAdvancedSearch
  autoload :Configurable, 'blacklight_advanced_search/configurable'
  autoload :QueryParser, 'blacklight_advanced_search/advanced_query_parser'
  extend Configurable
  def self.init
    logger.info("BLACKLIGHT: initialized with BlacklightAdvancedSearch.config: #{BlacklightAdvancedSearch.config.inspect}")
  end

  def self.logger
    RAILS_DEFAULT_LOGGER
  end

end
