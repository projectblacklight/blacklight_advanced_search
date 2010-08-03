module ApplicationHelper

  def facet_in_params?(field, value)
    (params[:f] and params[:f][field] and params[:f][field].include?(value)) or (params[:fq] and params[:fq][field] and params[:fq][field].keys.include?(value))
  end
  
  
  # adds the value and/or field to params[:f]
  # Does NOT remove request keys and otherwise ensure that the hash
  # is suitable for a redirect. See
  # add_facet_params_and_redirect
  def add_facet_params(field, value)
    p = params.dup
    # Need to merge into fq param if there is an fq param.
    if p[:fq]
      p[:fq]||={}
      p[:fq][field]||={}
      # we use a value of 2 to denote that this facet will be ANDed.
      p[:fq][field].merge!({value => 2})
    else
      p[:f]||={}
      p[:f][field] ||= []
      p[:f][field].push(value)
    end
    p
  end
  
  # copies the current params (or whatever is passed in as the 3rd arg)
  # removes the field value from params[:f] and params[:fq]
  # removes the field if there are no more values in params[:f][field]
  # completely removes the params[:fq] because of OR logic
  # removes additional params (page, id, etc..)
  def remove_facet_params(field, value, source_params=params)
    p = source_params.dup.symbolize_keys!
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p[:f] = p[:f].dup.symbolize_keys! if p[:f]
    p[:fq] = p[:fq].dup.symbolize_keys! if p[:fq]
    p.delete :page
    p.delete :id
    p.delete :counter
    p.delete :commit
    p[:fq][field] = p[:fq][field].delete_if{|k,v| k == value} if p[:fq] and p[:fq][field] and p[:fq][field][value]
    p[:fq].delete(field) if p[:fq] and p[:fq][field] and  p[:fq][field].size == 0
    p[:f][field] = p[:f][field] - [value] if p[:f] and p[:f][field]
    p[:f].delete(field) if p[:f][field].size == 0 if p[:f] and p[:f][field]
    p
  end
  
  def remove_advanced_query_params(value, source_params=params)
    p = source_params.dup.symbolize_keys!
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get removed in the show view...
    p.delete :page
    p.delete :id
    p.delete :total
    p.delete :counter
    p.delete :commit
    if p.has_key?(value.split("=").first.to_sym)
      p.delete value.split("=").first.to_sym
    end
    p
  end
  
  # Search History and Saved Searches display
  def link_to_previous_search(params)
    if params[:search_field] == BlacklightAdvancedSearch.config[:advanced][:search_field]
      query = BlacklightAdvancedSearch::QueryParser.new(params,BlacklightAdvancedSearch.config[:advanced]).user_friendly
      query_part = query[:q].map{|q|q[0]}.join(" ")
      facet_part = query[:fq].to_s.blank? ? "" : "{#{query[:fq].join(" ")}}"
    else
      query_part = case
                     when params[:q].blank?
                       ""
                     when (params[:search_field] == Blacklight.default_search_field[:key])
                       params[:q]
                     else
                       "#{Blacklight.label_for_search_field(params[:search_field])}:(#{params[:q]})"
                   end      
    
      facet_part = 
      if params[:f]
        tmp = 
        params[:f].collect do |pair|
          "#{Blacklight.config[:facet][:labels][pair.first]}:#{pair.last}"
        end.join(" AND ")
        "{#{tmp}}"
      else
        ""
      end
    end
    link_to("#{query_part} #{facet_part}", catalog_index_path(params))
  end

  def remove_advanced_keyword_query(field, my_params = params)
    my_params.delete(field)
    return my_params
  end
end