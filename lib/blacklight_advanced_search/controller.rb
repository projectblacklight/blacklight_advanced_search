# This module gets included into CatalogController, or another SearchHelper
# includer, to override
module BlacklightAdvancedSearch::Controller
  if Blacklight::VERSION < '7.27'
    # before Blacklight 7.27, the provided search service didn't receive this controller
    def advanced_search
      (@response, _deprecated_document_list) = blacklight_advanced_search_form_search_service.search_results
    end

    private

    def blacklight_advanced_search_form_search_service
      form_search_state = search_state_class.new(blacklight_advanced_search_form_params, blacklight_config, self)

      search_service_class.new(config: blacklight_config, search_state: form_search_state, user_params: form_search_state.to_h, **search_service_context)
    end

    def blacklight_advanced_search_form_params
      {}
    end
  end
end
