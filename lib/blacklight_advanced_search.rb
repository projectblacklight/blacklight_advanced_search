module BlacklightAdvancedSearch
  autoload :QueryParser, 'blacklight_advanced_search/advanced_query_parser'

  extend Blacklight::SearchFields # for search field config, so we can use same format as BL, or use ones already set in BL even. 
    
  def self.init
    apply_config_defaults!  
    
    logger.info("BLACKLIGHT: initialized with BlacklightAdvancedSearch.config: #{ config.inspect }")
  end

  def self.logger
    RAILS_DEFAULT_LOGGER
  end

  # Hash of our config. The :search_fields key in hash is used by
  # Blacklight::SearchFields module, must be an array of search field
  # definitions compatible with that module, or if missing will
  # inherit Blacklight.config[:search_fields]
  def self.config
    @config ||= {}
  end

  # Has to be called in an after_initialize, to make sure Blacklight.config
  # is already defined. 
  def self.apply_config_defaults!
  
   config[:url_key] ||= "advanced"
   config[:qt] ||= Blacklight.config[:default_qt] ||  
      (Blacklight.config[:default_solr_params] && Blacklight.config[:default_solr_params][:qt])
   config[:form_solr_parameters] ||= {}

   
   config[:search_fields] ||= Blacklight.config[:search_fields].find_all do |field_def|
     (field_def[:qt].nil? || field_def[:qt] == config[:qt]) &&
     field_def[:include_in_advanced_search] != false
   end
   

   config
  end
  

  def self.solr_local_params_for_search_field(key)
  
    field_def = search_field_def_for_key(key)

    solr_params = (field_def[:solr_parameters] || {}).merge(field_def[:solr_local_parameters] || {})

    solr_params.collect do |key, val|
      key.to_s + "=" + solr_param_quote(val)
    end.join(" ")
    
    end

    def self.solr_param_quote(val)
      unless val =~ /^[a-zA-Z$_\-\^]+$/
        val = "'" + val.gsub("'", "\\\'").gsub('"', "\\\"") + "'"
      end
      return val
    end

end
