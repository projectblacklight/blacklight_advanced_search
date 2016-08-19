module BlacklightAdvancedSearch
  # Can extract query elements from rails #params query params, and then parse
  # them and convert them into a solr query with #to_solr
  #
  # #keyword_queries and #filters, which just return extracted elements of query
  # params, may also be useful in display etc.
  class QueryParser
    include ParsingNestingParser # only one strategy currently supported. if BlacklightAdvancedSearch.config[:solr_type] == "parsing_nesting"
    include FilterParser
    attr_reader :config, :params

    def initialize(params,config)
      @params = Blacklight::SearchState.new(params, config).to_h
      @config = config
    end

    def to_solr
      @to_solr ||= begin
        {
          :q => process_query(params,config),
          :fq => generate_solr_fq()
        }
      end
    end

    # Returns "AND" or "OR", how #keyword_queries will be combined
    def keyword_op
      @params["op"] || "AND"
    end

    # extracts advanced-type keyword query elements from query params,
    # returns as a kash of field => query.
    # see also keyword_op
    def keyword_queries
      unless(@keyword_queries)
        @keyword_queries = {}

        return @keyword_queries unless @params[:search_field] == ::AdvancedController.blacklight_config.advanced_search[:url_key]

        config.search_fields.each do | key, field_def |
          if ! @params[ key.to_sym ].blank?
            @keyword_queries[ key ] = @params[ key.to_sym ]
          end
        end
      end
      return @keyword_queries
    end

    # extracts advanced-type filters from query params,
    # returned as a hash of field => [array of values]
    def filters
      unless (@filters)
        @filters = {}
        return @filters unless @params[:f_inclusive] && @params[:f_inclusive].respond_to?(:each_pair)
        @params[:f_inclusive].each_pair do |field, value_array|
          @filters[field] ||= value_array.dup
        end
      end
      return @filters
    end

    def filters_include_value?(field, value)
      filters[field.to_s].try {|array| array.include? value}
    end

    def empty?
      filters.empty? && keyword_queries.empty?
    end

  end
end
