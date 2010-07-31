module BlacklightAdvancedSearch
  class QueryParser
    include DismaxQueryParser if BlacklightAdvancedSearch.config[:advanced][:solr_type] == "dismax"
    include EdismaxQueryParser if BlacklightAdvancedSearch.config[:advanced][:solr_type] == "edismax"
    include FilterParser
    attr_reader :to_solr, :user_friendly, :op
    def initialize(params,config)
      # Assign UserFriendlyQuery object
      @user_friendly = UserFriendlyQueryParser.new(params,config)
      
      # Assign solr params
      @to_solr = {:q => process_query(params,config), :fq => process_filters(params)}
      
      # Assign the operator that is being used (AND/OR)
      @op = params[:op]
    end
  end
end