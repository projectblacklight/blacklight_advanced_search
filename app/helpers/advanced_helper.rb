# Helper methods for the advanced search form
module AdvancedHelper

  # Fill in default from existing search, if present
  # -- if you are using same search fields for basic
  # search and advanced, will even fill in properly if existing
  # search used basic search on same field present in advanced.
  def label_tag_default_for(key)
    if (! params[key].blank?)
      return params[key]
    elsif params["search_field"] == key
      return params["q"]
    else
      return nil
    end
  end

  # Is facet value in adv facet search results?
  def facet_value_checked?(field, value)
    params[:f_inclusive] && params[:f_inclusive][field] && params[:f_inclusive][field][value]
  end

  # Current params without fields that will be over-written by adv. search,
  # or other fields we don't want.
  def advanced_search_context
    my_params = params.except :page, :commit, :f_inclusive, :q, :search_field, :op, :action, :index, :sort, :controller

    my_params.except! *search_fields_for_advanced_search.map { |key, field_def| field_def[:key] }
  end

  def search_fields_for_advanced_search
    @search_fields_for_advanced_search ||= begin
      blacklight_config.search_fields.select { |k,v| v.include_in_advanced_search or v.include_in_advanced_search.nil? }
    end
  end

end
