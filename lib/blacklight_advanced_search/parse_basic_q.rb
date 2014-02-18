# A solr search logic mix-in to CatalogController. 
# If mixed-in, adds Advanced Search parsing behavior
# to queries entered on basic/standard/simple search
# form too, for boolean expressions. 
#
#  simply:
#    include BlacklightAdvancedSearch::ParseBasicQ
# in your CatalogController
module BlacklightAdvancedSearch::ParseBasicQ
  extend ActiveSupport::Concern
  
  included do
    solr_search_params_logic << :add_advanced_parse_q_to_solr
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
      field_def = search_field_def_for_key( req_params[:search_field]) ||
        default_search_field
        
              
      # If the individual field has advanced_parse_q suppressed, punt
      return if field_def[:advanced_parse] == false  
        
      solr_direct_params = field_def[:solr_parameters] || {}
      solr_local_params = field_def[:solr_local_parameters] || {}
      
      # See if we can parse it, if we can't, we're going to give up
      # and just allow basic search, perhaps with a warning.
      begin
        adv_search_params = ParsingNesting::Tree.parse(req_params[:q], blacklight_config.advanced_search[:query_parser]).to_single_query_params( solr_local_params )
        
        BlacklightAdvancedSearch.deep_merge!(solr_parameters, solr_direct_params)
        BlacklightAdvancedSearch.deep_merge!(solr_parameters, adv_search_params)        
      rescue Parslet::UnconsumedInput => e 
        # do nothing, don't merge our input in, keep basic search
        # optional TODO, display error message in flash here, but hard to 
        # display a good one. 
        return
      end
    end
  end

end
