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
      def self.filter(controller)      
        params = controller.send(:params)

        if params[:f_inclusive]
          legacy_converted = false

          params[:f_inclusive].each_pair do |field, value|
            if value.kind_of? Hash
              # old style! convert!
              legacy_converted = true
              params[:f_inclusive][field] = value.keys
            end
          end

          if legacy_converted
            controller.send(:redirect_to, params, :status => :moved_permanently) 
          end
        end
      end
    end
  end