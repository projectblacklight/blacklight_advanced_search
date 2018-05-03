# frozen_string_literal: true

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

    def css_asset
      application_css_location = Dir["app/assets/stylesheets/application{.css,.scss,.css.scss}"].first

      unless application_css_location
        say_status "skipped", "Can not find an application.css, did not insert our require", :red
        return
      end

      original_css = File.binread(application_css_location)
      if original_css.include?("require 'blacklight_advanced_search'")
        say_status("skipped", "insert into app/assets/stylesheets/application.css", :yellow)
      else
        insert_into_file application_css_location, :before => "*/" do
          "\n *= require 'blacklight_advanced_search'\n\n"
        end
      end
    end

    def js_asset
      application_js_location = Dir["app/assets/javascripts/application{.js,.coffee,.js.coffee}"].first

      unless application_js_location
        say_status "skipped", "Can not find an application.js, did not insert our require", :red
        return
      end

      original_js = File.binread(application_js_location)
      if original_js.include?("require 'blacklight_advanced_search'")
        say_status("skipped", "insert into app/assets/javascripts/application.js", :yellow)
      else
        insert_into_file application_js_location, :after => %r{//= require ['"]?jquery['"]?$} do
          "\n//= require 'blacklight_advanced_search'\n\n"
        end
      end
    end
  end
end
