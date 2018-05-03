# frozen_string_literal: true

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

    config.default_solr_params = { qt: 'search', rows: 10 }

    config.add_facet_field 'language_ssim', label: 'Language', limit: true
    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = {
        'spellcheck.dictionary': 'title',
        qf: '${title_qf}',
        pf: '${title_pf}'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_parameters = {
        'spellcheck.dictionary': 'author',
        qf: '${author_qf}',
        pf: '${author_pf}'
      }
    end

    config.add_search_field('dummy_field') do |field|
      field.solr_parameters = {
        'spellcheck.dictionary': 'author',
        qf: '${author_qf}',
        pf: '${author_pf}'
      }
    end
  end
end
