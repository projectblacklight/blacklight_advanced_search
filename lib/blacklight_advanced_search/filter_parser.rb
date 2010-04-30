module BlacklightAdvancedSearch::FilterParser
  def process_filters(params)
    if(params.has_key?(:fq))
      text = []
      params[:fq].each do |facet,value|
        temp = ""
        facet_queries = []
        extra_values = []
        value.each do |key,value|
          if value == "2"
            extra_values << key
          else
            facet_queries << key
          end
        end
        temp << "#{facet}:("
        facet_queries.flatten.each do |query|
          temp << "#{'"'}#{query}#{'"'}"
          temp << " OR " unless query == facet_queries.last
        end
        (!extra_values.empty? and !facet_queries.empty?) ? temp << " AND " : nil
        extra_values.each do |query|
          temp << "#{'"'}#{query}#{'"'}"
          temp << " AND " unless query == extra_values.last
        end
        temp << ")"
        text << temp
      end
      text.join(", ")
    end
  end
end