module BlacklightAdvancedSearch::EdismaxQueryParser
  def process_query(params,config)
    text = []
    params.each do |field,values| 
      if config.has_key?("#{field}".to_sym) and !params[field].blank? and field.to_s != "search_field"
        temp_text = '_query_:"{!edismax'
        config["#{field}".to_sym].each do |field_type,handler|
          temp_text << " #{field_type.to_s}=$#{handler}"
        end
        temp_text << "}#{values}\""
        text << temp_text
      end
    end
    return "*:*" if text.empty?
    text.join(" #{params[:op]} ")
  end

end