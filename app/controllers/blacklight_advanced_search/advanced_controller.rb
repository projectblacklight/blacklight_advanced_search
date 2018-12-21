# Need to sub-class CatalogController so we get all other plugins behavior
# for our own "inside a search context" lookup of facets.
class BlacklightAdvancedSearch::AdvancedController < CatalogController
  def index
    @response = get_advanced_search_facets unless request.method == :post
  end

  protected

  # Override to use the engine routes
  def search_action_url(options = {})
    blacklight_advanced_search_engine.url_for(options.merge(action: 'index'))
  end

  def get_advanced_search_facets
    # We want to find the facets available for the current search, but:
    # * IGNORING current query (add in facets_for_advanced_search_form filter)
    # * IGNORING current advanced search facets (remove add_advanced_search_to_solr filter)
    response, _ = search_service.search_results do |search_builder|
      search_builder.except(:add_advanced_search_to_solr).append(:facets_for_advanced_search_form)
    end

    response
  end
end
