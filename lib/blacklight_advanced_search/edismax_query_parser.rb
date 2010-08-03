module BlacklightAdvancedSearch::EdismaxQueryParser
  def process_query(params,config)
    text = []
    keyword_queries.each do |field,values|       
        temp_text = '_query_:"{!edismax'
        config["#{field}".to_sym].each do |field_type,handler|
          temp_text << " #{field_type.to_s}=$#{handler}"
        end
        temp_text << "}#{values}\""
        text << temp_text      
    end
    return text.join(" #{params[:op]} ")
  end

end