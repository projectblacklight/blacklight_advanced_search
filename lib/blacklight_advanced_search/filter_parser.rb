module BlacklightAdvancedSearch::FilterParser
  # Returns an array of solr :fq params. taking advanced search inclusive
  # facet value lists out of params. 
  def generate_solr_fq
    filters.map do |solr_field, value_list|
      "#{solr_field}:(" +
        Array(value_list).collect {|v| '"' + v.gsub('"', '\"') +'"' }.join(" OR  ") +
        ")"
    end
  end
end