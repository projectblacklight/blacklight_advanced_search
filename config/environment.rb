# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
Rails::Initializer.run do |config|
  config.action_controller.session = {
    :session_key => '_blacklight_advanced_search_session',
    :secret      => '3e37cf3b7a9a3359f437aac207241fd25c2e2a107f85b2e6d32e0b5e3795e75fdb094b9d045d8c40e9ae2b38063c8926ef01b1e03946652eadf96c653d6effa9'
  }
  config.active_record = false
  config.gem 'rspec', :version=>'1.3.0', :lib=>false
  config.gem 'rspec-rails', :version=>'1.3.2', :lib=>false
end