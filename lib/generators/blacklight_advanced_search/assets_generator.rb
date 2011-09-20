# Copy BlacklightAdvancedSearch assets to public folder in current app. 
# If you want to do this on application startup, you can
# add this next line to your one of your environment files --
# generally you'd only want to do this in 'development', and can
# add it to environments/development.rb:
#       require File.join(BlacklightAdvancedSearch.root, "lib", "generators", "blacklight", "assets_generator.rb")
#       BlacklightAdvancedSearch::AssetsGenerator.start(["--force", "--quiet"])


# Need the requires here so we can call the generator from environment.rb
# as suggested above. 
require 'rails/generators'
require 'rails/generators/base'
module BlacklightAdvancedSearch
  class AssetsGenerator < Rails::Generators::Base
    source_root File.join(BlacklightAdvancedSearch::Engine.root, 'app', 'assets')

    def assets
      if BlacklightAdvancedSearch.use_asset_pipeline?
        original_css = File.binread("app/assets/stylesheets/application.css")
        if original_css.include?("require 'blacklight_advanced_search'")
          say_status("skipped", "insert into app/assets/stylesheets/application.css", :yellow)
        else        
          insert_into_file "app/assets/stylesheets/application.css", :before => "*/" do
            "\n *= require 'blacklight_advanced_search'\n\n"
          end
        end
        
        original_js = File.binread("app/assets/javascripts/application.js")
        if original_js.include?("require 'blacklight_advanced_search'")
          say_status("skipped", "insert into app/assets/javascripts/application.js", :yellow)
        else
          insert_into_file "app/assets/javascripts/application.js", :after => "//= require jquery" do
            "\n//= require 'blacklight_advanced_search'\n\n"
          end
        end
      else
        directory("stylesheets/blacklight_advanced_search", "public/stylesheets")
        directory("javascripts/blacklight_advanced_search", "public/javascripts")        
      end
    end

  end
end

