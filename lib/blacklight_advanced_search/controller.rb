require 'blacklight_advanced_search/parsing_nesting_parser'

# This module gets included into CatalogController, or another SolrHelper
# includer, to add behavior into solr_search_params_logic. 
module BlacklightAdvancedSearch::Controller
  extend ActiveSupport::Concern

  included do
    # default adv config values
    self.blacklight_config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    self.blacklight_config.advanced_search[:qt] ||= 'advanced'
    self.blacklight_config.advanced_search[:url_key] ||= 'advanced'
    self.blacklight_config.advanced_search[:query_parser] ||= 'dismax'
    self.blacklight_config.advanced_search[:form_solr_parameters] ||= {}    
    
    
    # Parse app URL params used for adv searches 
    solr_search_params_logic << :add_advanced_search_to_solr
    
    # Display advanced search constraints properly
    helper BlacklightAdvancedSearch::RenderConstraintsOverride
    helper BlacklightAdvancedSearch::CatalogHelperOverride
    helper_method :is_advanced_search?
  end
  
  def is_advanced_search? req_params = params
    (req_params[:search_field] == self.blacklight_config.advanced_search[:url_key]) ||
          req_params[:f_inclusive]
  end
  
  # this method should get added into the solr_search_params_logic
  # list, in a position AFTER normal query handling (:add_query_to_solr),
  # so it'll overwrite that if and only if it's an advanced search.
  # adds a 'q' and 'fq's based on advanced search form input. 
  def add_advanced_search_to_solr(solr_parameters, req_params = params)
    # If we've got the hint that we're doing an 'advanced' search, then
    # map that to solr #q, over-riding whatever some other logic may have set, yeah.
    # the hint right now is :search_field request param is set to a magic
    # key. OR of :f_inclusive is set for advanced params, we need processing too.     
    if is_advanced_search? req_params
      # Set this as a controller instance variable, not sure if some views/helpers depend on it. Better to leave it as a local variable
      # if not, more investigation later.       
      @advanced_query = BlacklightAdvancedSearch::QueryParser.new(req_params, self.blacklight_config )      
      BlacklightAdvancedSearch.deep_merge!(solr_parameters, @advanced_query.to_solr )
      if @advanced_query.keyword_queries.length > 0
        # force :qt if set, fine if it's nil, we'll use whatever CatalogController
        # ordinarily uses.         
        solr_parameters[:qt] = self.blacklight_config.advanced_search[:qt]
        solr_parameters[:defType] = "lucene"        
      end
      
    end
  end
          
  
end

  


  

