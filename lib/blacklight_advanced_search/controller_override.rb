# This module gets added on to CatalogController, mainly to override
# Blacklight::SolrHelper methods like #solr_search_params

module BlacklightAdvancedSearch::ControllerOverride

  def solr_search_params(extra_params = {})
    # Call superclass implementation, ordinary solr_params
    solr_params = super(extra_params)

    #Annoying thing where default behavior is to mix together
    #params from request and extra_params argument, so we
    #must do that too.
    req_params = params.merge(extra_params)
    
    # Now do we need to do fancy advanced stuff?
    if req_params[:search_field] == BlacklightAdvancedSearch.config[:advanced][:search_field]
      # Set this as a controller instance variable, not sure if some views/helpers depend on it. Better to leave it as a local variable
      # if not, more investigation later.       
      @advanced_query = BlacklightAdvancedSearch::QueryParser.new(req_params, BlacklightAdvancedSearch.config[:advanced])
      
      solr_params.merge!( @advanced_query.to_solr )
      
    end

    return solr_params
  end

  
end
