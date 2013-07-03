require 'blacklight'

module BlacklightAdvancedSearch
  class Engine < Rails::Engine
  
    # Do these things in a to_prepare block, to try and make them work
    # in development mode with class-reloading. The trick is we can't
    # be sure if the controllers we're modifying are being reloaded in
    # dev mode, if they are in the BL plugin and haven't been copied to
    # local, they won't be. But we do our best.
    config.to_prepare do    

      

      # Ordinary module over-ride to CatalogController
      CatalogController.send(:include,  
          BlacklightAdvancedSearch::Controller  
      ) unless
      CatalogController.include?(   
          BlacklightAdvancedSearch::Controller 
        )
      
      
      
      SearchHistoryController.send(:helper,
        BlacklightAdvancedSearch::RenderConstraintsOverride 
      ) unless
        SearchHistoryController.helpers.is_a?( 
          BlacklightAdvancedSearch::RenderConstraintsOverride 
        )
        
      SavedSearchesController.send(:helper,
        BlacklightAdvancedSearch::RenderConstraintsOverride 
      ) unless
        SearchHistoryController.helpers.is_a?( 
          BlacklightAdvancedSearch::RenderConstraintsOverride 
        )
        
    end
  end
end
