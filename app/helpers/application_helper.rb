module ApplicationHelper

  def facet_in_params?(field, value)
    (params[:f] and params[:f][field] and params[:f][field].include?(value)) or (params[:f_inclusive] and params[:f_inclusive][field] and params[:f_inclusive][field].keys.include?(value))
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
    p[:f_inclusive] = p[:f_inclusive].dup.symbolize_keys! if p[:fq]
    p.delete :page
    p.delete :id
    p.delete :counter
    p.delete :commit
    p[:f_inclusive][field] = p[:f_inclusive][field].delete_if{|k,v| k == value} if p[:f_inclusive] and p[:f_inclusive][field] and p[:f_inclusive][field][value]
    p[:f_inclusive].delete(field) if p[:f_inclusive] and p[:f_inclusive][field] and  p[:f_inclusive][field].size == 0
    p[:f][field] = p[:f][field] - [value] if p[:f] and p[:f][field]
    p[:f].delete(field) if p[:f][field].size == 0 if p[:f] and p[:f][field]
    p
  end
  
  
  def remove_advanced_keyword_query(field, my_params = params)
    my_params.delete(field)
    return my_params
  end
end