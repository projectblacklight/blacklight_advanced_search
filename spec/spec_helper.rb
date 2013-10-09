ENV["RAILS_ENV"] = "test"

require File.expand_path("config/environment", ENV['RAILS_ROOT'] || File.expand_path("../internal", __FILE__))

require 'capybara/rspec'
require 'rspec/rails'
require 'capybara/rails'


RSpec.configure do |config|

end

