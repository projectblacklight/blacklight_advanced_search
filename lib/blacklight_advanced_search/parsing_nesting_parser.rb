require 'parsing_nesting/tree'
module BlacklightAdvancedSearch::ParsingNestingParser
  def process_query(_params, config)
    queries = keyword_queries.map do |field, query|
      ParsingNesting::Tree.parse(query, config.advanced_search[:query_parser]).to_query(local_param_hash(field, config))
    end
    queries.join(" #{keyword_op} ")
  end

  def local_param_hash(key, config)
    field_def = config.search_fields[key] || {}

    (field_def[:solr_adv_parameters] || field_def[:solr_parameters] || {}).merge(field_def[:solr_local_parameters] || {})
  end
end
