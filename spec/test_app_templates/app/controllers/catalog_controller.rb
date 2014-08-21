class CatalogController < ApplicationController
  include Blacklight::Catalog

  configure_blacklight do |config|
      config.default_solr_params = { 
        :qt => 'search',
        :rows => 10 
      }

      config.add_facet_field 'language_facet'

      config.add_search_field('title') do |field|
        field.solr_local_parameters = { :qf => "title_t", :pf => "title_t"}
      end

      config.add_search_field('author') do |field|
        field.solr_local_parameters = { :qf => "author_t", :pf => "author_t"}
      end

      config.add_search_field('dummy_field') do |field|
        field.include_in_advanced_search = false
        field.solr_local_parameters = { :qf => "author_t", :pf => "author_t"}
      end
    end
  end