# frozen_string_literal: true

require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../spec/test_app_templates', __dir__)

  def remove_index
    remove_file 'public/index.html'
    remove_file 'app/assets/images/rails.png'
  end

  def run_blacklight_generator
    say_status('warning', 'GENERATING BL', :yellow)

    generate 'blacklight:install'
  end

  def run_blacklight_advanced_search
    generate 'blacklight_advanced_search:install', '--force'
  end

  def run_test_support_generator
    say_status('warning', 'GENERATING test_support', :yellow)

    generate 'blacklight:test_support'
  end

  def copy_blacklight_catalog_controller
    copy_file 'app/controllers/catalog_controller.rb', force: true
  end
end
