module BlacklightAdvancedSearch
  class QueryParser
    include DismaxQueryParser if BlacklightAdvancedSearch.config[:solr_type] == "dismax"
    include EdismaxQueryParser if BlacklightAdvancedSearch.config[:solr_type] == "edismax"
    include ParsingNestingParser if BlacklightAdvancedSearch.config[:solr_type] == "parsing_nesting"
    include FilterParser
    attr_reader :to_solr
    def initialize(params,config)
      @params = HashWithIndifferentAccess.new(params)
      @config = config
      @to_solr = {:q => process_query(params,config), 
                  :fq => generate_solr_fq() }
    end

    # Returns "AND" or "OR", how #keyword_queries will be combined
    def keyword_op
      @params["op"] || "AND"
    end
    # returns advanced-type keyword queries, see also keyword_op
    def keyword_queries
      unless(@keyword_queries)
        @keyword_queries = {}

        return @keyword_queries unless @params[:search_field] == BlacklightAdvancedSearch.config[:url_key]
        
        @config[:search_fields].each do | field_def |
          key = field_def[:key]
          if ! @params[ key.to_sym ].blank?
            @keyword_queries[ key ] = @params[ key.to_sym ]
          end
        end
      end
      return @keyword_queries
    end
    # returns just advanced-type filters
    def filters
      unless (@filters)
        @filters = {}
        return @filters unless @params[:f_inclusive]
        @params[:f_inclusive].each_pair do |field, value_hash|
          value_hash.each_pair do |value, type|
            @filters[field] ||= []
            @filters[field] << value
          end
        end        
      end
      return @filters
    end

    def empty?
      filters.empty? && keyword_queries.empty?
    end
    
  end
end