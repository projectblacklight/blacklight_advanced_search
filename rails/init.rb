require 'blacklight_advanced_search'

# Require the Blacklight plugin to be installed
config.plugins = 'blacklight'

# Require the RubyTree gem which is needed for query parsing
config.gem 'rubytree', :lib => 'tree', :version => '0.5.2'

config.after_initialize do
  BlacklightAdvancedSearch.init
  
  Blacklight.config[:search_fields] << {:display_label => 'Advanced', :key => BlacklightAdvancedSearch.config[:search_field], :include_in_simple_select => false} if defined? :Blacklight

  CatalogController.send(:include, BlacklightAdvancedSearch::ControllerOverride  )
  CatalogController.helper( BlacklightAdvancedSearch::RenderConstraintsOverride )
  CatalogController.helper( BlacklightAdvancedSearch::CatalogHelperOverride )
  
  SearchHistoryController.helper( BlacklightAdvancedSearch::RenderConstraintsOverride )
end



