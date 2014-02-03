source 'http://rubygems.org'

gemspec

group :test do
  gem "bootstrap-sass"
  gem 'turbolinks'
end

gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
gem 'sqlite3', platform: :ruby

if File.exists?('spec/test_app_templates/Gemfile.extra')
  eval File.read('spec/test_app_templates/Gemfile.extra'), nil, 'spec/test_app_templates/Gemfile.extra'
end
