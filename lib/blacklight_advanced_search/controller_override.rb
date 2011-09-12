# This module gets included into CatalogController, or another SolrHelper
# includer, to add behavior into solr_search_params_logic. 
module BlacklightAdvancedSearch::ControllerOverride
  def self.included(klass)
    klass.solr_search_params_logic << :add_advanced_search_to_solr 
  end
  
  
  # this method should get added into the solr_search_params_logic
  # list, in a position AFTER normal query handling (:add_query_to_solr),
  # so it'll overwrite that if and only if it's an advanced search.
  # adds a 'q' and 'fq's based on advanced search form input. 
  def add_advanced_search_to_solr(solr_parameters, req_params = params)
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
  
  # This method can be included in solr_search_params_logic to have us
  # parse an ordinary entered :q for AND/OR/NOT and produce appropriate
  # Solr query. Note that it is NOT included in solr_search_params_logic
  # by default when this module is included, because it is optional behavior.
  # BlacklightAdvancedSearch init code will add it to CatalogController
  # if it's configured to do so. You can of course add it yourself
  # manually too. 
  #
  # Note: For syntactically invalid input, we'll just skip the adv
  # parse and send it straight to solr same as if advanced_parse_q
  # were not being used. 
  def add_advanced_parse_q_to_solr(solr_parameters, req_params = params)
    unless req_params[:q].blank?
      field_def = Blacklight.search_field_def_for_key( req_params[:search_field]) ||
        Blacklight.default_search_field
        
              
      # If the individual field has advanced_parse_q suppressed, punt
      return if field_def[:advanced_parse_q] == false  
        
      solr_direct_params = field_def[:solr_parameters] || {}
      solr_local_params = field_def[:solr_local_parameters] || {}
      
      # See if we can parse it, if we can't, we're going to give up
      # and just allow basic search, perhaps with a warning.
      begin
        adv_search_params = ParsingNesting::Tree.parse(req_params[:q]).to_single_query_params( solr_local_params )
        
        deep_merge!(solr_parameters, solr_direct_params)
        
        deep_merge!(
          solr_parameters, 
          adv_search_params    
         )
      rescue Parslet::UnconsumedInput => e 
        # do nothing, don't merge our input in, keep basic search
        # optional TODO, display error message in flash here, but hard to 
        # display a good one. 
        return
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

  


  

