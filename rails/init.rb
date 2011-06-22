require 'blacklight_advanced_search'

# Don't run any init code in testing environment. rspec sometimes uses
# "in-memory" for testing environment. All the init code tries to patch
# and use files that just aren't there in the testing environment. This
# stuff is a work in progress, figuring out how to properly test plugins.
# will be MUCH better in Rails3, when everything including Blacklight is
# a gem. 
unless Rails.env == "test" || Rails.env == "in_memory"
  
  # Require the Blacklight plugin to be installed. But not in testing
  # environment, makes things simpler. 
  config.plugins = 'blacklight' 
  
  
  # Require the RubyTree gem which is needed for query parsing
  config.gem 'rubytree', :lib => 'tree', :version => '0.5.2'
  
  
  
  config.after_initialize do
    BlacklightAdvancedSearch.init
    
    Blacklight.config[:search_fields] << {:display_label => 'Advanced', :key => BlacklightAdvancedSearch.config[:url_key], :include_in_simple_select => false, :include_in_advanced_search => false} if defined? :Blacklight
  
  
    # Do these things in a to_prepare block, to try and make them work
    # in development mode with class-reloading. The trick is we can't
    # be sure if the controllers we're modifying are being reloaded in
    # dev mode, if they are in the BL plugin and haven't been copied to
    # local, they won't be. But we do our best. 
    config.to_prepare do
      # Ordinary module over-ride to CatalogController
      CatalogController.send(:include,  
          BlacklightAdvancedSearch::ControllerOverride  
      ) unless
        CatalogController.include?(   
          BlacklightAdvancedSearch::ControllerOverride 
        )
        
        
      # And add in parsing of ordinary :q if requested
      if BlacklightAdvancedSearch.config[:advanced_parse_q] &&
         (! CatalogController.solr_search_params_logic.include?(:add_advanced_parse_q_to_solr))         
      CatalogController.solr_search_params_logic << 
        :add_advanced_parse_q_to_solr 
      end
      
      # Add helpers to CatalogController and SearchHistoryController. Use
      # some tricks to only add our helper once, may need to be done differently
      # in Rails3. 
      CatalogController.add_template_helper(
        BlacklightAdvancedSearch::RenderConstraintsOverride 
      ) unless 
          CatalogController.master_helper_module.include?(
            BlacklightAdvancedSearch::RenderConstraintsOverride
          )
          
      CatalogController.add_template_helper(
        BlacklightAdvancedSearch::CatalogHelperOverride 
      ) unless
        CatalogController.master_helper_module.include?( 
          BlacklightAdvancedSearch::CatalogHelperOverride 
        )
        
    
      SearchHistoryController.add_template_helper(
        BlacklightAdvancedSearch::RenderConstraintsOverride 
      ) unless
        SearchHistoryController.master_helper_module.include?( 
          BlacklightAdvancedSearch::RenderConstraintsOverride 
        )
        
      SavedSearchesController.add_template_helper(
        BlacklightAdvancedSearch::RenderConstraintsOverride 
      ) unless
        SavedSearchesController.master_helper_module.include?( 
          BlacklightAdvancedSearch::RenderConstraintsOverride 
        )

     # Weird hack to make sure our AdvancedController gets all the
     # helper methods from CatalogController. AdvancedController sub-classes
     # CatalogController, but since it's decleration is loaded before other
     # plugins get the chance to add helpers to CatalogController, they
     # may not take, we need to add em in now.
     CatalogController.master_helper_module.ancestors.each do |helper_module|
       AdvancedController.add_template_helper( helper_module ) unless AdvancedController.master_helper_module.include?( helper_module )
     end
        
        # Insert our stylesheet.  
        CatalogController.before_filter do |controller|          
          controller.stylesheet_links << ["advanced_results", {:plugin =>:blacklight_advanced_search}] unless controller.stylesheet_links.include?(["advanced_results", {:plugin =>:blacklight_advanced_search}])
        end
  
        
    end
  end
end


