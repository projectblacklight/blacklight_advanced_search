module BlacklightAdvancedSearch::EdismaxQueryParser
  def process_query(params,config)
    text = []
    keyword_queries.each do |field,values|       
        temp_text = '_query_:"{!edismax'

        temp_text << BlacklightAdvancedSearch.solr_local_params_for_search_field(key)
        
        temp_text << "}#{values}\""
        text << temp_text      
    end
    return  text.length > 0 ? "{!lucene} " +  text.join(" #{params[:op]} ") : nil
  end

end