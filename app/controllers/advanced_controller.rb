# Need to sub-class CatalogController so we get all other plugins behavior
# for our own "inside a search context" lookup of facets. 
class AdvancedController < CatalogController
  include AdvancedHelper # so we get the #advanced_search_context method
  
  before_filter :setup_advanced_search_css, :setup_advanced_search_js, :only => :index
  
  def index
    unless request.method==:post
      @response = get_advanced_search_facets
    end
  end

  protected
  def get_advanced_search_facets
    
    search_context_params = {}
    if (advanced_search_context.length > 0 )
      # We have a search context, need to fetch facets from within
      # that context.
      search_context_params = solr_search_params
      # Don't want to include the 'q' from basic search in our search
      # context. Kind of hacky becuase solr_search_params insists on
      # using controller.params, not letting us over-ride. 
      search_context_params.delete(:q)
      search_context_params.delete("q")
      
      # But need to delete any facet-related params, or anything else
      # we want to set ourselves or inherit from Solr request handler
      # defaults. 
      search_context_params.delete_if do |k, v|
        k = k.to_s
        (["facet.limit", "facet.sort", "f", "facets", "facet.fields", "qt", "per_page"].include?(k) ||                
          k =~ /f\..+\.facet\.limit/ ||
          k =~ /f\..+\.facet\.sort/
        )        
      end
    end

    input = HashWithIndifferentAccess.new
    input.merge!( search_context_params )
    input.merge!( :qt => BlacklightAdvancedSearch.config[:qt] , :per_page => 0)
    input.merge!( BlacklightAdvancedSearch.config[:form_solr_parameters] )
    
    
    Blacklight.solr.find(input.to_hash)
  end
  def setup_advanced_search_css
    stylesheet_links << ["blacklight_advanced_search_styles", {:plugin=>:blacklight_advanced_search}]
  end
  def setup_advanced_search_js
    javascript_includes << ["blacklight_advanced_search_javascript", {:plugin=>:blacklight_advanced_search}]
  end
end