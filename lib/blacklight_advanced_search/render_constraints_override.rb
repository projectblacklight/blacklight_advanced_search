# Meant to be applied on top of Blacklight view helpers, to over-ride
# certain methods from RenderConstraintsHelper (newish in BL), 
# to effect constraints rendering and search history rendering, 
module BlacklightAdvancedSearch::RenderConstraintsOverride

  #Over-ride of Blacklight method, provide advanced constraints if needed,
  # otherwise call super. Existence of an @advanced_query instance variable
  # is our trigger that we're in advanced mode. 
  def render_constraints_query(my_params = params)
    if (@advanced_query.nil? || @advanced_query.keyword_queries.empty? )
      return super(my_params)
    else
      content = ""
      @advanced_query.keyword_queries.each_pair do |field, query|
        label = BlacklightAdvancedSearch.search_field_def_for_key(field)[:display_label]
        content << render_constraint_element(
          label, query,
          :remove =>
            catalog_index_path(remove_advanced_keyword_query(field,my_params))
        )
      end
      if (@advanced_query.keyword_op == "OR" &&   
          @advanced_query.keyword_queries.length > 1)
        content = '<span class="inclusive_or appliedFilter">' + '<span class="operator">Any of:</span>' + content + '</span>'
      end
      
      return content
    end
  end

  #Over-ride of Blacklight method, provide advanced constraints if needed,
  # otherwise call super. Existence of an @advanced_query instance variable
  # is our trigger that we're in advanced mode. 
  def render_constraints_filters(my_params = params)
    content = super(my_params)

    if (@advanced_query)
      @advanced_query.filters.each_pair do |field, value_list|
        label = Blacklight.config[:facet][:labels][field] or field.to_s.capitalize
        content << render_constraint_element(label, 
          value_list.join(" OR "),
          :remove => catalog_index_path( remove_advanced_filter_group(field, my_params) )
          )
      end
    end
    
    return content
  end

  def render_search_to_s_filters(my_params)
    content = super(my_params)
    
    advanced_query = BlacklightAdvancedSearch::QueryParser.new(my_params, BlacklightAdvancedSearch.config )
    
    if (advanced_query.filters.length > 0)
      advanced_query.filters.each_pair do |field, values|
        label = Blacklight.config[:facet][:labels][field] or field.to_s.capitalize
      
        content << render_search_to_s_element( 
          label,
          values.join(" OR ")
        )
      end      
    end
    return content
  end

  def render_search_to_s_q(my_params)    
    content = super(my_params)

    advanced_query = BlacklightAdvancedSearch::QueryParser.new(my_params, BlacklightAdvancedSearch.config )

    if (advanced_query.keyword_queries.length > 1 &&
        advanced_query.keyword_op == "OR")
        # Need to do something to make the inclusive-or search clear

        display_as = advanced_query.keyword_queries.collect do |field, query|
          h( BlacklightAdvancedSearch.search_field_def_for_key(field)[:display_label] + ": " + query )
        end.join(" ; ")
        
        content << render_search_to_s_element("Any of",
          display_as,
          :escape_value => false
        )
    elsif (advanced_query.keyword_queries.length > 0) 
      advanced_query.keyword_queries.each_pair do |field, query|
        label = BlacklightAdvancedSearch.search_field_def_for_key(field)[:display_label]

        content << render_search_to_s_element(label, query)
      end    
    end
    
    return content
  end
  
end
