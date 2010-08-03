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
  SearchHistoryController.helper( BlacklightAdvancedSearch::RenderConstraintsOverride )
end

unless File.exists? File.join(Rails.root, 'config', 'initializers', 'blacklight_advanced_search_config.rb')
  raise "The Blacklight Advanced Search plugin requires a config/initializers/blacklight_advanced_search_config.rb file. You may need to run the rake task to install the plugin from your app. rake rails:template LOCATION=vendor/plugins/blacklight_advanced_search/template.rb "
end
unless File.read(File.join(Rails.root,'app','helpers','application_helper.rb')).scan("require 'vendor/plugins/blacklight_advanced_search/app/helpers/application_helper.rb'")
  puts "WARNING: Your ApplicationHelper is not requiring the blacklight_advanced_search ApplicationHelper\nWARNING: Please add the line require 'vendor/plugins/blacklight_advanced_search/app/helpers/application_helper.rb' to your ApplicationHelper in order for the BlacklightAdvancedSearch plugin to work as intended"
end

