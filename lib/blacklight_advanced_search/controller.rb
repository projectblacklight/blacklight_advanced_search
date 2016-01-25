require 'blacklight_advanced_search/parsing_nesting_parser'

# This module gets included into CatalogController, or another SearchHelper
# includer, to add advanced search behavior
module BlacklightAdvancedSearch::Controller
  extend ActiveSupport::Concern

  included do
    # Display advanced search constraints properly
    helper BlacklightAdvancedSearch::RenderConstraintsOverride
    helper BlacklightAdvancedSearch::CatalogHelperOverride
    helper_method :is_advanced_search?, :advanced_query
  end

  def is_advanced_search? req_params = params
    (req_params[:search_field] == blacklight_config.advanced_search[:url_key]) ||
    req_params[:f_inclusive]
  end

  def advanced_query
    BlacklightAdvancedSearch::QueryParser.new(params, blacklight_config) if is_advanced_search?
  end
end
