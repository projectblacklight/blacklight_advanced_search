require 'parslet'
require 'parsing_nesting/tree'
module BlacklightAdvancedSearch
  module AdvancedSearchBuilder

    include Blacklight::SearchFields

    def is_advanced_search?
      (blacklight_params[:search_field] == self.blacklight_config.advanced_search[:url_key]) || blacklight_params[:f_inclusive]
    end

    # this method should get added into the search_params_logic
    # list, in a position AFTER normal query handling (:add_query_to_solr),
    # so it'll overwrite that if and only if it's an advanced search.
    # adds a 'q' and 'fq's based on advanced search form input. 
    def add_advanced_search_to_solr(solr_parameters)
      # If we've got the hint that we're doing an 'advanced' search, then
      # map that to solr #q, over-riding whatever some other logic may have set, yeah.
      # the hint right now is :search_field request param is set to a magic
      # key. OR of :f_inclusive is set for advanced params, we need processing too.     
      if is_advanced_search?
        # Set this as a controller instance variable, not sure if some views/helpers depend on it. Better to leave it as a local variable
        # if not, more investigation later.       
        advanced_query = BlacklightAdvancedSearch::QueryParser.new(blacklight_params, self.blacklight_config )      
        BlacklightAdvancedSearch.deep_merge!(solr_parameters, advanced_query.to_solr )
        if advanced_query.keyword_queries.length > 0
          # force :qt if set, fine if it's nil, we'll use whatever CatalogController
          # ordinarily uses.         
          solr_parameters[:qt] = self.blacklight_config.advanced_search[:qt]
          solr_parameters[:defType] = "lucene"        
        end
        
      end
    end

    # Different versions of Parslet raise different exception classes,
    # need to figure out which one exists to rescue
    @@parslet_failed_exceptions = if defined? Parslet::UnconsumedInput
      [Parslet::UnconsumedInput]
    else
      [Parslet::ParseFailed]
    end
    
    
    # This method can be included in search_params_logic to have us
    # parse an ordinary entered :q for AND/OR/NOT and produce appropriate
    # Solr query.
    #
    # Note: For syntactically invalid input, we'll just skip the adv
    # parse and send it straight to solr same as if advanced_parse_q
    # were not being used. 
    def add_advanced_parse_q_to_solr(solr_parameters)
      unless scope.params[:q].blank?
        field_def = search_field_def_for_key( scope.params[:search_field]) ||
          default_search_field
          
                
        # If the individual field has advanced_parse_q suppressed, punt
        return if field_def[:advanced_parse] == false  
          
        solr_direct_params = field_def[:solr_parameters] || {}
        solr_local_params = field_def[:solr_local_parameters] || {}
        
        # See if we can parse it, if we can't, we're going to give up
        # and just allow basic search, perhaps with a warning.
        begin
          adv_search_params = ParsingNesting::Tree.parse(scope.params[:q], blacklight_config.advanced_search[:query_parser]).to_single_query_params( solr_local_params )

          BlacklightAdvancedSearch.deep_merge!(solr_parameters, solr_direct_params)
          BlacklightAdvancedSearch.deep_merge!(solr_parameters, adv_search_params)        
        rescue *@@parslet_failed_exceptions => e
          # do nothing, don't merge our input in, keep basic search
          # optional TODO, display error message in flash here, but hard to 
          # display a good one. 
          return
        end
      end
    end
  end
end