require 'rails/generators'

module BlacklightAdvancedSearch
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def inject_asset_requires
      generate "blacklight_advanced_search:assets"
    end
    
    
    def install_localized_search_form
      if options[:force] or yes?("Install local search form with advanced link? (y/N)", :green)
        # We're going to copy the search from from actual currently loaded
        # Blacklight into local app as custom local override -- but add our link at the end too. 
        source_file = File.read(File.join(Blacklight.root, "app/views/catalog/_search_form.html.erb"))

        new_file_contents = source_file + "\n\n<%= link_to 'More options', advanced_search_path(params.except(:controller, :action)), :class=>'advanced_search'%>"

        create_file("app/views/catalog/_search_form.html.erb", new_file_contents)      
      end
    end
  end

end
