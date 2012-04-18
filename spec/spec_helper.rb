require 'rubygems'
require 'bundler'

Bundler.require :default, :development

ENV["RAILS_ENV"] = "test"

require 'blacklight/engine'
require 'rsolr'
require 'rsolr-ext'
require 'capybara/rspec'
Combustion.initialize!

class SolrDocument
  include Blacklight::Solr::Document
end

require 'rspec/rails'
require 'capybara/rails'


RSpec.configure do |config|

end

