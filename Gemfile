source 'http://rubygems.org'

gemspec

gem 'rails', '~> 4.0'

group :test do
  gem "bootstrap-sass"
  gem 'turbolinks'
end

gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
gem 'sqlite3', platform: :ruby

# These need to be listed here explicitly for engine_cart testing to work,
# not really sure why the existing gemspec and Gemfile of test app aren't enough. 
gem 'jquery-rails'
gem 'blacklight_marc'
gem 'sass-rails'


if File.exists?('spec/test_app_templates/Gemfile.extra')
  eval File.read('spec/test_app_templates/Gemfile.extra'), nil, 'spec/test_app_templates/Gemfile.extra'
end
