require 'rails/generators'

class BlacklightAdvancedSearchGenerator < Rails::Generators::Base
  def inject_asset_requires
    say "`rails g blacklight_advanced_search` is deprecated; use blacklight_advanced_search:install instead", :red
    generate "blacklight_advanced_search:install"
  end
end
