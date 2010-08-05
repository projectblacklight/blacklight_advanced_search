## 
# This example config file is set up to work using the Solr request handler
# called "advanced" in the example Blacklight solrconfig.xml:
# http://github.com/projectblacklight/blacklight-jetty/blob/master/solr/conf/solrconfig.xml
#
# Using a seperate request handler is just one option, in many cases it's
# simpler to use your default solr request handler set in Blacklight itself,
# and you may not need any of this configuration. See README. 

BlacklightAdvancedSearch.config.merge!(
  # This will be used later when edismax is returning the expected results
  #:solr_type => "edismax",
  :solr_type => "dismax",
  # :search_field => "advanced", # name of key in Blacklight URL, no reason to change usually. 
  :qt => "advanced" # name of Solr request handler, leave unset to use the same one as your Blacklight.config[:default_qt]  
)


  # You don't need to specify search_fields, if you leave :qt unspecified
  # above, and have search field config in Blacklight already using that
  # same qt, the plugin will simply use them. But if you'd like to use a
  # different solr qt request handler, or have another reason for wanting
  # to manually specify search fields, you can. Uses the hash format
  # specified in Blacklight::SearchFields

  BlacklightAdvancedSearch.config[:search_fields] = search_fields = []
  search_fields << {
    :key =>  'author',
    :solr_local_parameters => {
      :pf => "$pf_author",
      :qf => "$qf_author"
    }
  }
  
  search_fields << {
    :key =>  'title',
    :solr_local_parameters => {
      :pf => "$pf_title",
      :qf => "$qf_title"
    }
  }
  
  search_fields << {
    :key =>  'subject',
    :solr_local_parameters => {
      :pf => "$pf_subject",
      :qf => "$qf_subject"
    }
  }

  search_fields << {
    :key =>  'keyword',
    :solr_local_parameters => {
      :pf => "$pf_keyword",
      :qf => "$qf_keyword"
    }
  }

  search_fields << {
    :key =>  'numbers',
    :solr_local_parameters => {
      :pf => "$pf_number",
      :qf => "$qf_number"
    }
  }

##
# The advanced search form displays facets as a limit option.
# By default it will use whatever facets, if any, are returned
# by the Solr qt request handler in use. However, you can use
# this config option to have it request other facet params than
# default in the Solr request handler, in desired.

# BlacklightAdvancedSearch.config[:form_solr_parameters] = {
  # "facet.field" => [
    # "format",
    # "lc_1letter_facet",
    # "language_facet"    
  # ],
  # "facet.limit" => -1,  # all facet values
  # "facet.sort" => "index"  # sort by index value (alphabetically, more or less)
# }
