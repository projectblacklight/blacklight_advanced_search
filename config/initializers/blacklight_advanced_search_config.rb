BlacklightAdvancedSearch.configure(:shared) do |config|
  config[:advanced] = {
    # This will be used later when edismax is returning the expected results
    #:solr_type => "edismax",
    #:search_field => "edismax",
    :solr_type => "dismax",
    :search_field => "advanced",
    :fields => [:author,:title,:subject,:keyword,:numbers],
    # Author 
    :author => {
      :pf => "pf_author",
      :qf => "qf_author"
    },

    # Title
    :title => {
      :pf => "pf_title",
      :qf => "qf_title"
    },

    # Subject
    :subject => {
      :pf => "pf_subject",
      :qf => "qf_subject"
    },
  
    # Keword (metadata)
    :keyword => {
      :pf => "pf_keyword",
      :qf => "qf_keyword"
    },
    
    # Number
    :numbers => {
      :qf => "qf_number"
    }
  }
end