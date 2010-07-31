class BlacklightAdvancedSearch::UserFriendlyQueryParser  
  
  #  The idea here is that the UI can iterate through the fields like this:
  #  user_friendly = BlacklightAdvancedSearch::QueryParser.user_friendly
  #  user_friendly.each do |key,field|
  #    "#{field} #{link_to([x],localized_params.merge(key=>nil))}"
  #  end
  
  attr_reader :keyword_fields, :facets
  def initialize(params,config)
    process_query_params(params,config)
    process_filter_params(params)
  end
  
  def process_query_params(params,config)
    @keyword_fields = []
    params.each do |field,values|
      if config.has_key?("#{field}".to_sym) and !params[field].blank? and field.to_s != "search_field"
        self.create_user_friendly_method(field.to_sym){"#{field.to_s.capitalize} = (#{values})"}
        @keyword_fields << field.to_sym
      end
    end
  end
  
  def process_filter_params(params)
    @facets = []
    if params.has_key?(:fq)
      params[:fq].each do |facet,values|
        or_facets = []
        and_facets = []
        values.each do |value,key|
          # Facets with a key of 2 were selected from the search results of an advanced search.
          # We treat any subsequent facets selected from the search results as ANDed facets.
          key == "2" ? and_facets << value : or_facets << value
        end
        @facets << {:field=>facet,:or=>or_facets,:and=>and_facets}
      end
    end
  end
  
  def each(&block)
    self.keyword_fields.each do |field|
      block.call(field,self.send(field))
    end
  end
  
  def create_user_friendly_method(name, &block)
    self.class.send(:define_method, name, &block)
  end
  
end
