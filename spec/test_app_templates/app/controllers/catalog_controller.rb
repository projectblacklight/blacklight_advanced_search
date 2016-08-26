class CatalogController < ApplicationController
  include Blacklight::Catalog
  include BlacklightAdvancedSearch::Controller

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}

    config.default_solr_params = {
      :qt => 'search',
      :rows => 10
    }

    config.add_facet_field 'language_facet'

    config.add_search_field('title') do |field|
      field.solr_local_parameters = { :qf => "title_t", :pf => "title_t" }
    end

    config.add_search_field('author') do |field|
      field.solr_local_parameters = { :qf => "author_t", :pf => "author_t" }
    end

    config.add_search_field('dummy_field') do |field|
      field.include_in_advanced_search = false
      field.solr_local_parameters = { :qf => "author_t", :pf => "author_t" }
    end
  end
end
