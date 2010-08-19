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
    my_params = params.dup
    [:page, :commit, :f_inclusive, :q, :search_field, :op, :action, :index, :sort, :controller].each do |bad_key|
      my_params.delete(bad_key)
    end
    BlacklightAdvancedSearch.config[:search_fields].each do |field_def|
      my_params.delete( field_def[:key] )
    end
    my_params
  end
  
end
