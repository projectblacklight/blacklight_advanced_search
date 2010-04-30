class AdvancedController < ApplicationController
  # Uncomment out this before filter when the head_items branch gets merged into master.
  #before_filter :setup_advanced_search_css, :setup_advanced_search_js, :only => :index
  def index
    unless request.method==:post
      @response = get_advanced_search_facets
    end
  end

  protected
  def get_advanced_search_facets
    input = {
      :qt=>Blacklight.config[:default_qt],
      :per_page=>0
    }
    Blacklight.solr.find(input)
  end
  def setup_advanced_search_css
    stylesheet_links << ["blacklight_advanced_search_styles", {:plugin=>:blacklight_advanced_search}]
  end
  def setup_advanced_search_js
    javascript_includes << ["blacklight_advanced_search_javascript", {:plugin=>:blacklight_advanced_search}]
  end
end