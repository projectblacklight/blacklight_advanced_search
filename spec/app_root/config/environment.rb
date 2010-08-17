require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|

  config.cache_classes = false
  config.whiny_nils = true
  config.action_controller.session = {:key => 'rails_session', :secret => 'd229e4d22437432705ab3985d4d246'}
  config.plugin_locators.unshift(
    Class.new(Rails::Plugin::Locator) do
      def plugins
        [Rails::Plugin.new(File.expand_path('.'))]
      end
    end
  ) unless defined?(PluginTestHelper::PluginLocator)

  # jrochkind addition to plugin_test_helper generated rails stub. 
  # Adds our plugin code itself to the Rails load path, so it will be
  # auto-loaded.  Not entirely sure why plugin_test_helper doesn't do
  # this itself.
  config.load_paths << File.expand_path(File.dirname(__FILE__)+ "../../../../lib")
  config.load_paths << File.expand_path(File.dirname(__FILE__)+ "../../../../app/helpers")
  config.load_paths << File.expand_path(File.dirname(__FILE__)+ "../../../../app/models")

  # We only get one view path, we want it to be our plugins, not the
  # pseudo-app_root
  config.view_path = File.expand_path(File.dirname(__FILE__)+ "../../../../app/views")

  
  
end
