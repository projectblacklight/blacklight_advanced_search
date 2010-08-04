BlacklightAdvancedSearch.config.merge!(
  # This will be used later when edismax is returning the expected results
  #:solr_type => "edismax",
  :solr_type => "dismax",
  :search_field => "advanced", # name of key in Blacklight URL
  :qt => "advanced" # name of Solr request handler  
)


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
    
    