require 'rails/generators'

class BlacklightAdvancedSearchGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  require File.expand_path('../assets_generator.rb', __FILE__)
  def copy_public_assets
    BlacklightAdvancedSearch::AssetsGenerator.start
  end

end
