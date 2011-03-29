module BlacklightAdvancedSearch::ParsingNestingParser
  
  def process_query(params,config)
    queries = []
    keyword_queries.each do |field,query| 
      queries << ParsingNesting::Tree.parse(query).to_query( local_param_hash(field)  )            
    end
    queries.join( ' ' + keyword_op + ' ')
  end
  
  def local_param_hash(key)
    field_def = BlacklightAdvancedSearch.search_field_def_for_key(key)

    (field_def[:solr_parameters] || {}).merge(field_def[:solr_local_parameters] || {})
  end
  
end