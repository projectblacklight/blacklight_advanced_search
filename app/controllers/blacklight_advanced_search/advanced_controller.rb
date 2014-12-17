# Need to sub-class CatalogController so we get all other plugins behavior
# for our own "inside a search context" lookup of facets. 
class BlacklightAdvancedSearch::AdvancedController < CatalogController
  include AdvancedHelper # so we get the #advanced_search_context method


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
      # that context -- but we dont' want to search within any
      # existing :q or ADVANCED facets, so we remove those params.
      adv_keys = blacklight_config.search_fields.keys.map {|k| k.to_sym}
      trimmed_params = params.except *adv_keys
      trimmed_params.delete(:f_inclusive) # adv facets
      
      search_context_params = solr_search_params(trimmed_params)

      # Don't want to include the 'q' from basic search in our search
      # context. Kind of hacky becuase solr_search_params insists on
      # using controller.params, not letting us over-ride. 
      search_context_params.delete(:q)
      search_context_params.delete("q")
      
      # Also delete any facet-related params, or anything else
      # we want to set ourselves
      search_context_params.delete_if do |k, v|
        k = k.to_s
        (["facet.limit", "facet.sort", "f", "facets", "facet.fields", "per_page"].include?(k) ||                
          k =~ /f\..+\.facet\.limit/ ||
          k =~ /f\..+\.facet\.sort/
        )        
      end
    end

    input = HashWithIndifferentAccess.new
    input.merge!( search_context_params )

    input[:per_page] = 0 # force

    # force if set
    input[:qt] = blacklight_config.advanced_search[:qt] if blacklight_config.advanced_search[:qt] 
    
    input.merge!( blacklight_config.advanced_search[:form_solr_parameters] ) if blacklight_config.advanced_search[:form_solr_parameters]

    # ensure empty query is all records, to fetch available facets on entire corpus
    input[:q] ||= '{!lucene}*:*'
    
    # solr_repository was introduced in Blacklight 5.8
    if respond_to? :solr_repository
      solr_repository.search(input)
    else
      # first arg nil, use default search path.
      find nil, input.to_hash
    end
  end
end
