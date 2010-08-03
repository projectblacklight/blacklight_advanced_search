module BlacklightAdvancedSearch::FilterParser
  # Returns an array of solr :fq params. taking advanced search inclusive
  # facet value lists out of params. 
  def generate_solr_fq
      filter_queries = []
      filters.each do |solr_field, value_list|
        filter_queries << "#{solr_field}:(" +
          value_list.collect {|v| '"' + v.gsub('"', '\"') +'"' }.join(" OR  ") +
          ")"
      end
      return filter_queries
  end
end