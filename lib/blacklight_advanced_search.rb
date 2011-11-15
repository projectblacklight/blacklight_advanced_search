module BlacklightAdvancedSearch
  autoload :Controller, 'blacklight_advanced_search/controller'
  autoload :RenderConstraintsOverride, 'blacklight_advanced_search/render_constraints_override'
  autoload :CatalogHelperOverride, 'blacklight_advanced_search/catalog_helper_override'
  autoload :QueryParser, 'blacklight_advanced_search/advanced_query_parser'
  autoload :ParsingNestingParser, 'blacklight_advanced_search/parsing_nesting_parser'
  autoload :FilterParser, 'blacklight_advanced_search/filter_parser'

  require 'blacklight_advanced_search/version'
  require 'blacklight_advanced_search/engine'

end
