This is an advanced search plugin for Blacklight ( http://www.projectblacklight.org ).

[![Gem Version](https://badge.fury.io/rb/blacklight_advanced_search.svg)](http://badge.fury.io/rb/blacklight_advanced_search)  [![Build Status](https://travis-ci.org/projectblacklight/blacklight_advanced_search.svg)](https://travis-ci.org/projectblacklight/blacklight_advanced_search)

## Blacklight version compatibility

This is a plugin for [Blacklight](http://github.com/projectblacklight/blacklight)

It has been hard to keep track of which versions of `blacklight_advanced_search`
work with which versions of `blacklight`. Some notes:

* versions 5.x of Advanced Search plugin should work with Blacklight >= 5.1 and < 6 -- we now synchronize the _major_ version number between `blacklight` and `blacklight_advanced_search`.
  * `blacklight_advanced_search` 5.x changes the URL query param format for advanced 'inclusive'
     facet selections, from the advanced form. If you'd like to keep old-style possibly
     bookmarked URLs working, by redirecting to new format, add this to your
     `CatalogController`:

            before_filter BlacklightAdvancedSearch::RedirectLegacyParamsFilter, :only => :index

* version 2.2 of `blacklight_advanced_search` should work with `blacklight` 4.x.
* versions `1.2.*` of Advanced Search plugin can work with blacklight 3.2.2 through latest 3.2.x
* 1.2.0 was an aborted version, don't use it, if you did, re-do your configuration according to current instructions and delete any local ./app/controllers/advanced_controller.rb file.
* advanced search 1.1.x versions will work with Blacklights 3.0.x through 3.1.x
* advanced search plugin latest 0.X.X version will work with Blacklight 2.9/Rails2.
* Older tagged versions of Advanced Search may work with even older BL.

## Installation

### Blacklight 3.x/Rails 3

Add to your application's Gemfile:

    gem "blacklight_advanced_search"

then run 'bundle install'.  Then run:

    rails generate blacklight_advanced_search

* The 'generate' command will install 'require' statements for the plugin's assets into your application's application.js/application.css asset pipeline files
* And it can optionally install a localized search form with a link to advanced search. If you've already localized your search form you'll want to do this manually instead.

You may want turn to enable AND/OR/NOT parsing even in ordinary search, this is not on by default.  See "Expression parsing in ordinary search" below.

## Accessing

The advanced search form will be available in your app at /advanced, and in your app using
routing helper `advanced_search_path`.

    advanced_search_path

You can also send the advanced search form url parameters representing a search, to have the form add on additional 'advanced' criteria to the search.  For example:

    advanced_search_path( params )

By default there won't be any links in your application to the search form. If you've heavily customized your app, you can put them wherever you want as above.

However, especially if your app isn't much customized, the optional installer can write a localized Blacklight search form into your application with a 'more options' link to advanced. You may need to adjust your styles to make room for the new link, depending on what you've done with your app.


## Configuration

If your application uses a single Solr qt request handler for all its search fields, then this plugin may work well with no configuration.  Nonetheless, configuration is available to change or improve behavior, or to use a separate Solr request handler for the advanced search plugin. Most configuration takes place in your `./app/controllers/catalog_controller.rb` `configure_blacklight` block.


### Expression parsing in ordinary search

Turn this feature on by adding to your SearchBuilder definition:

    self.default_processor_chain << :add_advanced_parse_q_to_solr

This will intercept queries entered in ordinary Blacklight search interface, and parse them for AND/OR/NOT (and parens), producing appropriate Solr query. This allows single-field boolean expressions to be entered in ordinary search, providing a consistent experience with advanced search.

Individual blacklight 'search fields' can have advanced parsing turned off:

    config.add_search_field("something") do |field|
      # ...
      field.advanced_parse = false
    end


When this feature is turned on, queries that don't have any special operators (eg: AND, OR, NOT, parens) will still be passed to Solr much the same as they were before. But queries with special operators will have appropriate Solr queries generated for them, usually including nested "_query_" elements, to have the same meaning they would in advanced search. If a user enters something that is a syntax error for parsed search (for instance an unclosed phrase quote or paren), the logic will rescue from the parse erorr by running the exact user entered query direct to solr without advanced parsing.

Due to limitations of the logic, sometimes these generated Solr queries may not really be as simple as they could be, they may include a *single* nested _query_, which really doens't need to be a nested query at all, although it will still work fine.

If there'a a parse error trying to parse as boolean expression, it'll give up and pass the query on through same as it would without ParseBasicQ.

### Search fields

Your main blacklight search fields are generally defined in CatalogController blacklight_config using `add_search_field`. They are all by default used in advanced search.

If there are particular search fields in your main blacklight config you want excluded from the advanced search form, you can set ":include_in_advanced_search => false"

    config.add_search_field("isbn") do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = { :qf => "isbn_t" }
    end

If you want search fields ONLY available in advanced search, you can suppress them from ordinary search:

    config.add_search_field("publisher") do |field|
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "publisher_t" }
    end

All advanced search fields must share the same Solr request handler (":qt"). As such, search fields that use a custom ":qt" parameter may not be re-used by the advanced search plugin. However, you may use a separate Solr request handler than the Blacklight default. If you would like the advanced search to use a different Solr request handler than your app's default, set:

    config.advanced_search = {
      :qt => 'advanced'
    }

If you use a separate Solr request handler for advanced search, you must supply a completely separate list of search fields for the advanced search form, just define them with `:include_in_advanced_search => true` and `:include_in_simple_search => false` as above.

Additionally, to make your advanced search solr requests more concise, you are strongly encouraged to take advantage of the :local_solr_parameters option in your search field definition to use a solr parameter substitution with $variables.

    configure_blacklight do |config|
      config.add_search_field('author') do |field|
        field.solr_local_parameters = {
          :qf=>"$qf_author",
          :pf=>"$pf_author"
        }
      end
    end

Within your solrconfig.xml you may then provide the appropriate custom configuration.

    <requestHandler name="advanced" class="solr.SearchHandler" >
      <lst name="defaults">
        <!-- ... -->
        <str name="qf_author">
          author_1xx_unstem_search^200
          author_7xx_unstem_search^50
          author_8xx_unstem_search^10
          author_1xx_search^20       vern_author_1xx_search^20
          author_7xx_search^5        vern_author_7xx_search^5
          author_8xx_search          vern_author_8xx_search
        </str>
        <str name="pf_author">
          author_1xx_unstem_search^5000
          author_7xx_unstem_search^3000
          author_1xx_search^500        vern_author_1xx_search^500
          author_7xx_search^300        vern_author_7xx_search^300
          author_8xx_unstem_search^250
          author_8xx_search^200        vern_author_8xx_search^200
        </str>
      </lst>
    </requestHandler>

### Facets on advanced search form

By default, the advanced search form will show as limits whatever facets are configured as default in your Solr request handler.  To have the advanced search form request specific facets and/or specific facet parameters, you can set config[:form_solr_parameters].

    config.advanced_search = {
      :form_solr_parameters => {
        "facet.field" => ["format", "language_facet"],
        "facet.limit" => -1, # return all facet values
        "facet.sort" => "index" # sort by byte order of values
      }
    }

Multiply selected advanced search form facets are combined with `or` (ie `any` or `union`).

The default advanced search form facet display is very much like Blacklight's
sidebar facets (and uses some code straight from BL to render), but with checkboxes
next to each value.

### Advanced Search Config Options

Complete list of keys that can be supplied inside your configure_blacklight `advanced_search` block:

* :qt
  * Solr request handler to use for any search that includes advanced search criteria. Defaults to what the application has set as blacklight_config.default_solr_params[:qt]
* :form_solr_parameters
  * A hash of solr parameters which will be included in Solr request sent before display of advanced search form. Can be used to set facet parameters for advanced search form display.
* :query_parser
  * advanced searches are translated to solr nested queries, where the inner queries are of a dismax-type.
  By default, they are actually specifically 'dismax', but you can set :query_parser to 'edismax' instead.
  This may make additional features available like * wildcards in advanced searches; but it may also
  cause some user query elements to be interpreted as operators for edismax when they
  were intended as literals. Somewhat experimental. See Github issues #11 and #14.

## Customizing the advanced search form

Most of the labels on the advanced search form are [provided via Rails i18n](./config/locales), and can
be customized in a local app i18n file.

Additionally, you can override the templates from this gem used to display the form.
We've tried to break it up into partials at the right granularity for over-riding
in likely ways.  For one example, see the wiki page on [Adding a range limit to the advanced search form](https://github.com/projectblacklight/blacklight_advanced_search/wiki/Adding-a-range-limit-to-the-advanced-search-form).


## Translation to Solr Query, technical details

The code for mapping a user-entered query to a Solr query is called "nesting_parsing", and maps to a 'lucene' query parser query, with nested 'dismax' query parser queries.

Some technical details can be found in the nesting_parsing README: [https://github.com/projectblacklight/blacklight_advanced_search/tree/main/lib/parsing_nesting]

You may also find the rspecs for parsing a user-entered query and converting it to Solr illumnating:

1. Converting user-entered query to Solr: [https://github.com/projectblacklight/blacklight_advanced_search/blob/main/spec/parsing_nesting/to_solr_spec.rb]
2. Parsing user-entered query to internal syntax tree: [https://github.com/projectblacklight/blacklight_advanced_search/blob/main/spec/parsing_nesting/build_tree_spec.rb]

## Running tests


(Limited) test coverage is provided with rspec, run all tests (and start the jetty instance) by running:
   rake ci

from the blacklight_advanced_search directory. Note: you may need to `bundle install` first.


## To Do

* Alphabetical sorting of facet values returned by solr in count order (perhaps with limit).
* Parse for fielded search too like << title:"some title" >>.  'field:' that doesn't match an actual known field should be passed through same as now, while recognized fields should generate nested queries tied to those blacklight search types.
