# frozen_string_literal: true

# Returns a lambda that you can use with a before_filter in your
# CatalogController to catch and redirect query params using the old
# style, used prior to blacklight_advanced_search 5.0.
#
# This can be used to keep any old bookmarked URLs still working.
#
#     before_filter BlacklightAdvancedSearch::RedirectLegacyParamsFilter, :only => :index
#
module BlacklightAdvancedSearch
  class RedirectLegacyParamsFilter
    def self.before(controller)
      params = controller.send(:params)

      if params[:f_inclusive]&.respond_to?(:each_pair)
        legacy_converted = false

        params[:f_inclusive].each_pair do |field, value|
          next unless value.is_a? Hash
          # old style! convert!
          legacy_converted = true
          params[:f_inclusive][field] = value.keys
        end

        controller.send(:redirect_to, params, :status => :moved_permanently) if legacy_converted
      end
    end
  end
  end
