source 'http://rubygems.org'

gemspec

gem 'rails', '~> 4.0'

group :test do
  gem "bootstrap-sass"
  gem 'turbolinks'
end

gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
gem 'sqlite3', platform: :ruby
gem 'jquery-rails'
gem 'blacklight_marc'


if File.exists?('spec/test_app_templates/Gemfile.extra')
  eval File.read('spec/test_app_templates/Gemfile.extra'), nil, 'spec/test_app_templates/Gemfile.extra'
end
