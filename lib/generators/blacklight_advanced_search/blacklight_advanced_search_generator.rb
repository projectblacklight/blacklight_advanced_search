require 'rails/generators'

class BlacklightAdvancedSearchGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  require File.expand_path('../assets_generator.rb', __FILE__)  
  def inject_asset_requires
    BlacklightAdvancedSearch::AssetsGenerator.start
  end
  
  
  def install_localized_search_form
    if options[:force] or yes?("Install local search form with advanced link?")      
      copy_file("_search_form.html.erb", "app/views/catalog/_search_form.html.erb")      
    end
  end

end
