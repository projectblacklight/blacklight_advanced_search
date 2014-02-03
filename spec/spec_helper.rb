ENV["RAILS_ENV"] = "test"

require 'engine_cart'
EngineCart.load_application!


require 'capybara/rspec'
require 'rspec/rails'
require 'capybara/rails'


RSpec.configure do |config|

end

