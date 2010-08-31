# This module gets added on to CatalogController, mainly to override
# Blacklight::SolrHelper methods like #solr_search_params

module BlacklightAdvancedSearch::ControllerOverride

  def solr_search_params(extra_params = {})    
    # Call superclass implementation, ordinary solr_params
    solr_params = super(extra_params)

    # When we're in advanced controller, we're fetching the search
    # context, and don't want to include any of our own stuff.
    # This is a hacky hard-coded way to do it, but needed
    # because solr_search_params is hard-coded to use current req params,
    # not just passed in arg override.
    return solr_params if self.class == AdvancedController

    #Annoying thing where default behavior is to mix together
    #params from request and extra_params argument, so we
    #must do that too.
    req_params = params.merge(extra_params)
    
    # Now do we need to do fancy advanced stuff?
    if (req_params[:search_field] == BlacklightAdvancedSearch.config[:url_key] ||
      req_params[:f_inclusive])
      # Set this as a controller instance variable, not sure if some views/helpers depend on it. Better to leave it as a local variable
      # if not, more investigation later.       
      @advanced_query = BlacklightAdvancedSearch::QueryParser.new(req_params, BlacklightAdvancedSearch.config )
      
      solr_params = deep_safe_merge(solr_params, @advanced_query.to_solr )
      if @advanced_query.keyword_queries.length > 0
        # force :qt if set
        solr_params[:qt] = BlacklightAdvancedSearch.config[:qt]
        solr_params[:defType] = "lucene"
      end
      
    end

    return solr_params
  end

  protected

  # Merges new_hash into source_hash, without modifying arguments, but
  # will merge nested arrays and hashes too. Also will NOT merge nil or blank
  # from new_hash into old_hash
  def deep_safe_merge(source_hash, new_hash)
    source_hash.merge(new_hash) do |key, old, new|
      if new.respond_to?(:blank) && new.blank?
        old        
      elsif (old.kind_of?(Hash) and new.kind_of?(Hash))
        deep_merge(old, new)
      elsif (old.kind_of?(Array) and new.kind_of?(Array))
        old.concat(new).uniq
      elsif new.nil?
        # Allowing nil values to over-write on merge messes things up.
        # don't set a nil value if you really want to force blank, set
        # empty string. 
        old
      else
        new
      end
    end
  end


  
end
