# Meant to be applied on top of Blacklight view helpers, to over-ride
# certain methods from RenderConstraintsHelper (newish in BL), 
# to effect constraints rendering and search history rendering, 
module BlacklightAdvancedSearch::ViewHelperOverride

  #Over-ride of Blacklight method, provide advanced constraints if needed,
  # otherwise call super. Existence of an @advanced_query instance variable
  # is our trigger that we're in advanced mode. 
  def render_constraints_query(my_params = params)
    if (@advanced_query.nil?)
      return super(my_params)
    else
      content = ""
      @advanced_query.user_friendly[:q].each do |query|
        # if the query parser returned data more reasonably granular, we
        # could call this method with label and value, but it doesn't (yet),
        # so we just stuff it all into value. TODO.       
        content << render_constraint_element(
          nil, query[0],
          :remove =>
            catalog_index_path(remove_advanced_query_params(query[1],my_params))
        )
      end
      return content
    end
  end

  #Over-ride of Blacklight method, provide advanced constraints if needed,
  # otherwise call super. Existence of an @advanced_query instance variable
  # is our trigger that we're in advanced mode. 
  def render_constraints_filters(my_params = params)
    if (@advanced_query.nil?)
      return super(my_params)
    else
      content = ""
      @advanced_query.user_friendly[:fq].each do |facet_display|
        # if the query parser returned data more reasonably granular, we
        # could call this method with label and value, but it doesn't (yet),
        # so we just stuff it all into value. TODO.
        # Also if query_parser API were different, we could possibly have
        # a :remove link here, but we can't with the data available to us now.
        content << render_constraint_element(nil, facet_display)        
      end
      return content      
    end
  end
      
  
end
