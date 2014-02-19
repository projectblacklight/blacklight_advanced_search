# Meant to be applied on top of Blacklight view helpers, to over-ride
# certain methods from RenderConstraintsHelper (newish in BL),
# to effect constraints rendering and search history rendering,
module BlacklightAdvancedSearch::RenderConstraintsOverride

  def query_has_constraints?(localized_params = params)
    if is_advanced_search? localized_params
      true
    else
      !(localized_params[:q].blank? and localized_params[:f].blank? and localized_params[:f_inclusive].blank?)
    end
  end

  #Over-ride of Blacklight method, provide advanced constraints if needed,
  # otherwise call super. Existence of an @advanced_query instance variable
  # is our trigger that we're in advanced mode.
  def render_constraints_query(my_params = params)
    if (@advanced_query.nil? || @advanced_query.keyword_queries.empty? )
      return super(my_params)
    else
      content = []
      @advanced_query.keyword_queries.each_pair do |field, query|
        label = search_field_def_for_key(field)[:label]
        content << render_constraint_element(
          label, query,
          :remove =>
            catalog_index_path(remove_advanced_keyword_query(field,my_params))
        )
      end
      if (@advanced_query.keyword_op == "OR" &&
          @advanced_query.keyword_queries.length > 1)
        content.unshift content_tag(:span, "Any of:", class:'operator')
        content_tag :span, class: "inclusive_or appliedFilter" do
          safe_join(content.flatten, "\n")
        end
      else
        safe_join(content.flatten, "\n")    
      end
    end
  end

  #Over-ride of Blacklight method, provide advanced constraints if needed,
  # otherwise call super. Existence of an @advanced_query instance variable
  # is our trigger that we're in advanced mode.
  def render_constraints_filters(my_params = params)
    content = super(my_params)

    if (@advanced_query)
      @advanced_query.filters.each_pair do |field, value_list|
        label = facet_field_label(field)
        content << render_constraint_element(label,
          safe_join(value_list, " <strong class='text-muted constraint-connector'>OR</strong> ".html_safe),
          :remove => catalog_index_path( remove_advanced_filter_group(field, my_params) )
          )
      end
    end

    return content
  end

  # override of BL method, so our inclusive facet selections
  # are still recgonized for eg highlighting facet with selected
  # values. 
  def facet_field_in_params?(field)
    return true if super

    # otherwise use our own logic. And work around a weird bug
    # in BL that assumes params[:f][field] will exist if facet_field_in_params?
    # hacky insistence on params[:f] etc won't be neccesary if after:
    # https://github.com/projectblacklight/blacklight/pull/790
    if  @advanced_query && @advanced_query.filters.keys.include?( field )
      params[:f] ||= {}
      params[:f][field] ||= []
      return true
    end

    return false
  end

  def render_search_to_s_filters(my_params)
    content = super(my_params)

    advanced_query = BlacklightAdvancedSearch::QueryParser.new(my_params, blacklight_config )

    if (advanced_query.filters.length > 0)
      advanced_query.filters.each_pair do |field, values|
        label = facet_field_label(field)

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

    advanced_query = BlacklightAdvancedSearch::QueryParser.new(my_params, blacklight_config )

    if (advanced_query.keyword_queries.length > 1 &&
        advanced_query.keyword_op == "OR")
        # Need to do something to make the inclusive-or search clear

        display_as = advanced_query.keyword_queries.collect do |field, query|
          h( search_field_def_for_key(field)[:label] + ": " + query )
        end.join(" ; ")

        content << render_search_to_s_element("Any of",
          display_as,
          :escape_value => false
        )
    elsif (advanced_query.keyword_queries.length > 0)
      advanced_query.keyword_queries.each_pair do |field, query|
        label = search_field_def_for_key(field)[:label]

        content << render_search_to_s_element(label, query)
      end
    end

    return content
  end

end
