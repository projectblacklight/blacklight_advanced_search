# This module gets added on to CatalogController, mainly to override
# Blacklight::SolrHelper methods like #solr_search_params
module BlacklightAdvancedSearch::ControllerOverride
  def self.included(klass)
    klass.solr_search_params_logic << :add_advanced_q_to_solr
  end
  
  
  # this method should get added into the solr_search_params_logic
  # list, in a position AFTER normal query handling (:add_query_to_solr),
  # so it'll overwrite that if and only if it's an advanced search. 
  def add_advanced_q_to_solr(solr_parameters, req_params = params)
    # If we've got the hint that we're doing an 'advanced' search, then
    # map that to solr #q, over-riding whatever some other logic may have set, yeah.
    # the hint right now is :search_field request param is set to a magic
    # key.     
    if (req_params[:search_field] == BlacklightAdvancedSearch.config[:url_key] ||
      req_params[:f_inclusive])
      # Set this as a controller instance variable, not sure if some views/helpers depend on it. Better to leave it as a local variable
      # if not, more investigation later.       
      @advanced_query = BlacklightAdvancedSearch::QueryParser.new(req_params, BlacklightAdvancedSearch.config )
      deep_merge!(solr_parameters, @advanced_query.to_solr )
      if @advanced_query.keyword_queries.length > 0
        # force :qt if set
        solr_parameters[:qt] = BlacklightAdvancedSearch.config[:qt] if BlacklightAdvancedSearch.config[:qt]
        solr_parameters[:defType] = "lucene"
      end
      
    end
  end

  
  protected
  # Merges new_hash into source_hash, without modifying arguments, but
  # will merge nested arrays and hashes too. Also will NOT merge nil or blank
  # from new_hash into old_hash      
  def deep_merge!(source_hash, new_hash)
    source_hash.merge!(new_hash) do |key, old, new|
      if new.respond_to?(:blank) && new.blank?
        old        
      elsif (old.kind_of?(Hash) and new.kind_of?(Hash))
        deep_merge!(old, new)
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

  


  

