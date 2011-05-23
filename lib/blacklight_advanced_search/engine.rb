require 'blacklight'
require 'blacklight_advanced_search'
require 'rails'

module BlacklightAdvancedSearch
  class Engine < Rails::Engine
    initializer 'blacklight_advanced_search.init', :after => 'blacklight.init' do |app|
      if defined? ActionController::Dispatcher
        ActionController::Dispatcher.to_prepare do
          BlacklightAdvancedSearch.init
          Blacklight.config[:search_fields] << {:display_label => 'Advanced', :key => BlacklightAdvancedSearch.config[:url_key], :include_in_simple_select => false, :include_in_advanced_search => false} if defined? :Blacklight
        end
      end
    end
  
    # Do these things in a to_prepare block, to try and make them work
    # in development mode with class-reloading. The trick is we can't
    # be sure if the controllers we're modifying are being reloaded in
    # dev mode, if they are in the BL plugin and haven't been copied to
    # local, they won't be. But we do our best. 
    config.to_prepare do
      # Ordinary module over-ride to CatalogController
      Blacklight::Catalog.send(:include,  
          BlacklightAdvancedSearch::Controller  
      ) unless
        Blacklight::Catalog.include?(   
          BlacklightAdvancedSearch::Controller 
        )
        
      SearchHistoryController.send(:helper,
        BlacklightAdvancedSearch::RenderConstraintsOverride 
      ) unless
        SearchHistoryController.helpers.is_a?( 
          BlacklightAdvancedSearch::RenderConstraintsOverride 
        )
    end
  end
end
