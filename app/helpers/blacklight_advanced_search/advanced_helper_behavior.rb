module BlacklightAdvancedSearch
  # implementation for AdvancedHelper
  module AdvancedHelperBehavior
    # Fill in default from existing search, if present
    # -- if you are using same search fields for basic
    # search and advanced, will even fill in properly if existing
    # search used basic search on same field present in advanced.
    def label_tag_default_for(key)
      if !params[key].blank?
        return params[key]
      elsif params["search_field"] == key
        return params["q"]
      else
        return nil
      end
    end

    # Is facet value in adv facet search results?
    def facet_value_checked?(field, value)
      BlacklightAdvancedSearch::QueryParser.new(params, blacklight_config).filters_include_value?(field, value)
    end

    def select_menu_for_field_operator
      options = {
        t('blacklight_advanced_search.all') => 'AND',
        t('blacklight_advanced_search.any') => 'OR'
      }.sort

      select_tag(:op, options_for_select(options, params[:op]), class: 'input-small')
    end

    # Current params without fields that will be over-written by adv. search,
    # or other fields we don't want.
    def advanced_search_context
      my_params = search_state.params_for_search.except :page, :f_inclusive, :q, :search_field, :op, :index, :sort

      my_params.except!(*search_fields_for_advanced_search.map { |_key, field_def| field_def[:key] })
    end

    def search_fields_for_advanced_search
      @search_fields_for_advanced_search ||= begin
        blacklight_config.search_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }
      end
    end

    def facet_field_names_for_advanced_search
      @facet_field_names_for_advanced_search ||= begin
        blacklight_config.facet_fields.select { |_k, v| v.include_in_advanced_search || v.include_in_advanced_search.nil? }.values.map(&:field)
      end
    end

    # Use configured facet partial name for facet or fallback on 'catalog/facet_limit'
    def advanced_search_facet_partial_name(display_facet)
      facet_configuration_for_field(display_facet.name).try(:partial) || "catalog/facet_limit"
    end
  end
end
