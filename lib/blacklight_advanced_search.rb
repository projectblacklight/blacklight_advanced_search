module BlacklightAdvancedSearch
  autoload :AdvancedSearchBuilder, 'blacklight_advanced_search/advanced_search_builder'
  autoload :Controller, 'blacklight_advanced_search/controller'
  autoload :RenderConstraintsOverride, 'blacklight_advanced_search/render_constraints_override'
  autoload :CatalogHelperOverride, 'blacklight_advanced_search/catalog_helper_override'
  autoload :QueryParser, 'blacklight_advanced_search/advanced_query_parser'
  autoload :ParsingNestingParser, 'blacklight_advanced_search/parsing_nesting_parser'
  autoload :FilterParser, 'blacklight_advanced_search/filter_parser'
  autoload :RedirectLegacyParamsFilter, 'blacklight_advanced_search/redirect_legacy_params_filter'

  require 'blacklight_advanced_search/version'
  require 'blacklight_advanced_search/engine'

  # Utility method used in our solr search logic.
  # Merges new_hash into source_hash, but will recursively
  # merge nested arrays and hashes too; also will NOT merge nil
  # or blank values from new_hash into source_hash, nil or blank values
  # in new_hash will not overwrite values in source_hash.
  def self.deep_merge!(source_hash, new_hash)
    # We used to use built-in source_hash.merge() with a block arg
    # to customize merge behavior, but that was breaking in some
    # versions of BL/Rails where source_hash was a kind of HashWithIndifferentAccess,
    # and hwia is unreliable in some versions of Rails. Oh well.
    # https://github.com/projectblacklight/blacklight/issues/827

    new_hash.each_pair do |key, new_value|
      old = source_hash.fetch(key, nil)

      source_hash[key] =
        if new_value.respond_to?(:blank) && new.blank?
          old
        elsif (old.is_a?(Hash) && new_value.is_a?(Hash))
          deep_merge!(old, new_value)
          old
        elsif (old.is_a?(Array) && new_value.is_a?(Array))
          old.concat(new_value).uniq
        elsif new_value.nil?
          # Allowing nil values to over-write on merge messes things up.
          # don't set a nil value if you really want to force blank, set
          # empty string.
          old
        else
          new_value
        end
    end
    source_hash
  end
end
