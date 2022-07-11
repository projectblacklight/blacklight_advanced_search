# Returns a lambda that you can use with a before_filter in your
# CatalogController to catch and redirect query params using the old
# style
#
# This can be used to keep any old bookmarked URLs still working.
#
#     before_action BlacklightAdvancedSearch::RedirectLegacyParamsFilter, :only => :index
#
module BlacklightAdvancedSearch
  class RedirectLegacyParamsFilter
    def self.before(controller)
      params = controller.send(:params)
      legacy_converted = false

      # This was used prior to blacklight_advanceod_search 8
      i = 0
      controller.blacklight_config.search_fields.each do |_key, field|
        next unless params[field.key].present?
        legacy_converted = true

        params[:clause] ||= {}
        params[:clause][i] = {
          field: field.key,
          query: params[field.key]
        }
        i += 1

        params.delete(field.key)
      end

      # This was used prior to blacklight_advanced_search 5.0.
      if params[:f_inclusive] && params[:f_inclusive].respond_to?(:each_pair)

        params[:f_inclusive].each_pair do |field, value|
          next unless value.is_a? Hash
          # old style! convert!
          legacy_converted = true
          params[:f_inclusive][field] = value.keys
        end
      end

      if legacy_converted
        controller.send(:redirect_to, controller.search_state.reset(params).to_h, :status => :moved_permanently)
      end
    end
  end
end
