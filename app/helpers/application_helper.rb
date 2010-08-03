module ApplicationHelper

  def facet_in_params?(field, value)
    (params[:f] and params[:f][field] and params[:f][field].include?(value)) or (params[:fq] and params[:fq][field] and params[:fq][field].keys.include?(value))
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
  
  
  def remove_advanced_keyword_query(field, my_params = params)
    my_params.delete(field)
    return my_params
  end
end