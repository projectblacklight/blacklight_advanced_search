module BlacklightAdvancedSearch
  class QueryParser
    include DismaxQueryParser if BlacklightAdvancedSearch.config[:advanced][:solr_type] == "dismax"
    include EdismaxQueryParser if BlacklightAdvancedSearch.config[:advanced][:solr_type] == "edismax"
    include FilterParser
    attr_reader :to_solr, :user_friendly
    def initialize(params,config)
      @params = params
      @config = config
      @to_solr = {:q => process_query(params,config), 
                  :fq => generate_solr_fq() }
    end

    # Returns "AND" or "OR", how #keyword_queries will be combined
    def keyword_op
      @params["op"]
    end
    # returns advanced-type keyword queries, see also keyword_op
    def keyword_queries
      unless(@keyword_queries)
        @keyword_queries = {}
        @config[:fields].each do |field|
          if ! @params[field].blank?
            @keyword_queries[field] = @params[field]
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
    
  end
end