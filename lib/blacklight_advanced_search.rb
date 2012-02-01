module BlacklightAdvancedSearch
  autoload :Controller, 'blacklight_advanced_search/controller'
  autoload :RenderConstraintsOverride, 'blacklight_advanced_search/render_constraints_override'
  autoload :CatalogHelperOverride, 'blacklight_advanced_search/catalog_helper_override'
  autoload :QueryParser, 'blacklight_advanced_search/advanced_query_parser'
  autoload :ParsingNestingParser, 'blacklight_advanced_search/parsing_nesting_parser'
  autoload :FilterParser, 'blacklight_advanced_search/filter_parser'
  autoload :ParseBasicQ, 'blacklight_advanced_search/parse_basic_q'

  require 'blacklight_advanced_search/version'
  require 'blacklight_advanced_search/engine'

  
  # Utility method used in our solr search logic. 
  # Merges new_hash into source_hash, but will recursively
  # merge nested arrays and hashes too; also will NOT merge nil
  # or blank values from new_hash into source_hash, nil or blank values
  # in new_hash will not overwrite values in source_hash. 
  def self.deep_merge!(source_hash, new_hash)
    source_hash.merge!(new_hash) do |key, old, new|
      if new.respond_to?(:blank) && new.blank?
        old        
      elsif (old.kind_of?(Hash) and new.kind_of?(Hash))
        deep_merge!(old, new)
      elsif (old.kind_of?(Array) and new.kind_of?(Array))
        old.concat(new).uniq
      elsif new.nil?
        # Allowing nil values to over-write on merge messes things up.
        # don't set a nil value if you really want to force blank, set
        # empty string. 
        old
      else
        new
      end
    end
  end
  
end
