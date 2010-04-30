module BlacklightAdvancedSearch::UserFriendlyQueryParser
  def process_friendly(params,config)
    text = []
    filters = []
    params.each do |field,values|
      if config.has_key?("#{field}".to_sym) and !params[field].blank? and field.to_s != "search_field"
        text << ["#{field.to_s.capitalize} = (#{values})","#{field}=#{values}"]
      end
    end
    if params.has_key?(:fq)
      params[:fq].each do |facet,value|
        temp = ""
        or_facets = []
        and_facets = []
        value.each do |key,value|
          if value == "2"
            and_facets << key
          else
            or_facets << key
          end
        end
        temp << "#{facet.split('_')[0].capitalize} = "
        or_facets.each do |facet|
          temp << facet
          temp << " OR " unless facet == or_facets.last
        end
        (!or_facets.empty? and !and_facets.empty?) ? temp << " AND " : nil
        and_facets.each do |facet|
          temp << facet
          temp << " AND " unless facet == and_facets.last
        end
        filters << temp
      end
    end
    {:q => text, :fq => filters.uniq}
  end
end