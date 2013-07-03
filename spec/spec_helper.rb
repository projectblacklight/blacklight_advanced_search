require 'rubygems'
require 'combustion'

ENV["RAILS_ENV"] = "test"

require 'capybara/rspec'
Combustion.initialize! :active_model, :action_controller

class SolrDocument
  include Blacklight::Solr::Document
end

require 'rspec/rails'
require 'capybara/rails'


RSpec.configure do |config|

end

