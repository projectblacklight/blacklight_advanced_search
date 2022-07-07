require 'parsing_nesting/tree'

module BlacklightAdvancedSearch
  # Can extract query elements from rails #params query params, and then parse
  # them and convert them into a solr query with #to_solr
  #
  # #keyword_queries and #filters, which just return extracted elements of query
  # params, may also be useful in display etc.
  class QueryParser
    attr_reader :config, :search_state

    def initialize(search_state, config)
      @search_state = search_state
      @config = config
    end

    def to_solr
      @to_solr ||= begin
        {
          q: process_query(config)
        }
      end
    end

    # Returns "AND" or "OR", how #keyword_queries will be combined
    def keyword_op
      op = search_state.params[:op]&.to_sym || :must

      if op == :should
        'OR'
      else
        'AND'
      end
    end

    def keyword_queries
      search_state.clause_params.values.select { |clause| clause[:query].present? }
    end

    def process_query(config)
      queries = keyword_queries.map do |clause|
        field = clause[:field]
        query = clause[:query]

        ParsingNesting::Tree.parse(query, config.advanced_search[:query_parser]).to_query(local_param_hash(field, config))
      end
      queries.join(" #{keyword_op} ")
    end

    def local_param_hash(key, config)
      field_def = config.search_fields[key] || {}

      (field_def[:solr_adv_parameters] || field_def[:solr_parameters] || {}).merge(field_def[:solr_local_parameters] || {})
    end
  end
end
