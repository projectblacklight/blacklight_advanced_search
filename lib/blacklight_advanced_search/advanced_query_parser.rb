module BlacklightAdvancedSearch
  class QueryParser
    include DismaxQueryParser if BlacklightAdvancedSearch.config[:advanced][:solr_type] == "dismax"
    include EdismaxQueryParser if BlacklightAdvancedSearch.config[:advanced][:solr_type] == "edismax"
    include UserFriendlyQueryParser
    include FilterParser
    attr_reader :to_solr, :user_friendly
    def initialize(params,config)
      @user_friendly = process_friendly(params,config)
      @to_solr = {:q => process_query(params,config), :fq => process_filters(params)}
    end
  end
end