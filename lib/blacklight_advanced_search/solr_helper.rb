module BlacklightAdvancedSearch::SolrHelper
  # a solr query method
  # this is used when selecting a search result: we have a query and a 
  # position in the search results and possibly some facets
  def get_single_doc_via_search(extra_controller_params={})
    solr_params = solr_search_params(extra_controller_params)
    solr_params[:per_page] = 1
    solr_params[:fl] = '*'
    if solr_params[:qt] == BlacklightAdvancedSearch.config[:advanced][:search_field]
      @advanced_query = BlacklightAdvancedSearch::QueryParser.new(extra_controller_params,BlacklightAdvancedSearch.config[:advanced])
    end
    Blacklight.solr.find(@advanced_query ? solr_params.merge(@advanced_query.to_solr) : solr_params).docs.first
  end
  
end