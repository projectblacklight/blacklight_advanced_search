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
  # Like Rails Hash#deep_merge, merges 2 hashes recursively, including nested Arrays and Hashes.
  # Unlike Rails Hash#deep_merge:
  # - will NOT merge nil values over existing ones
  # - will NOT merge (non-FalseClass) blank values
  # - WILL deduplicate values from arrays after merging them
  #
  # @param [Hash|HashWithIndifferentAccess] source_hash
  # @param [Hash|HashWithIndifferentAccess] new_hash
  # @return [Hash] the deeply merged hash
  # @see Rails #deep_merge http://apidock.com/rails/v4.2.1/Hash/deep_merge
  # @example new_hash = BlacklightAdvancedSearch.deep_merge(h1, h2)
  def self.deep_merge(source_hash, new_hash)
    source_hash.deep_merge(new_hash, &method(:merge_conflict_resolution))
  end

  # this one side-effects the first param
  # @see #deep_merge
  # @deprecated use `new_hash = BlacklightAdvancedSearch.deep_merge(h1, h2)` instead
  def self.deep_merge!(source_hash, new_hash)
    source_hash.deep_merge!(new_hash, &method(:merge_conflict_resolution))
  end

  # the arguments are set by what the Rails Hash.deep_merge supplies the block
  def self.merge_conflict_resolution(_key, old, new_value)
    return old if new_value.nil?
    return old if new_value.respond_to?(:blank?) && new_value.blank? && !new_value.is_a?(FalseClass)
    return old | new_value if old.is_a?(Array) && new_value.is_a?(Array)
    new_value
  end
end
