require 'rubygems'
require 'bundler'

Bundler.require :default, :development

require 'blacklight/engine'
require 'rsolr'
require 'rsolr-ext'
require 'capybara/rspec'
Combustion.initialize!

Blacklight.solr_config = { :url => 'http://127.0.0.1:8983/solr' }

class SolrDocument
  include Blacklight::Solr::Document
end

require 'rspec/rails'
require 'capybara/rails'


RSpec.configure do |config|

end

