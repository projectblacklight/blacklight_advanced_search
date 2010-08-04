class AdvancedController < ApplicationController
  before_filter :setup_advanced_search_css, :setup_advanced_search_js, :only => :index
  
  def index
    unless request.method==:post
      @response = get_advanced_search_facets
    end
  end

  protected
  def get_advanced_search_facets
    input = {
      :qt=>BlacklightAdvancedSearch.config[:qt],
      :per_page=>0
    }.merge( BlacklightAdvancedSearch.config[:form_solr_parameters] )
    Blacklight.solr.find(input)
  end
  def setup_advanced_search_css
    stylesheet_links << ["blacklight_advanced_search_styles", {:plugin=>:blacklight_advanced_search}]
  end
  def setup_advanced_search_js
    javascript_includes << ["blacklight_advanced_search_javascript", {:plugin=>:blacklight_advanced_search}]
  end
end