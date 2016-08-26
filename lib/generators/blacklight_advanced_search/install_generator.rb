require 'rails/generators'

module BlacklightAdvancedSearch
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def inject_asset_requires
      generate "blacklight_advanced_search:assets"
    end

    def inject_search_builder
      inject_into_file 'app/models/search_builder.rb', after: /include Blacklight::Solr::SearchBuilderBehavior.*$/ do
        "\n  include BlacklightAdvancedSearch::AdvancedSearchBuilder" \
        "\n  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]"
      end
    end

    def install_catalog_controller_mixin
      inject_into_class "app/controllers/catalog_controller.rb", "CatalogController" do
        "  include BlacklightAdvancedSearch::Controller\n"
      end
    end

    def configuration
      inject_into_file 'app/controllers/catalog_controller.rb', after: "configure_blacklight do |config|" do
        "\n    # default advanced config values" \
        "\n    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new" \
        "\n    # config.advanced_search[:qt] ||= 'advanced'" \
        "\n    config.advanced_search[:url_key] ||= 'advanced'" \
        "\n    config.advanced_search[:query_parser] ||= 'dismax'" \
        "\n    config.advanced_search[:form_solr_parameters] ||= {}\n"
      end
    end

    def install_search_history_controller
      copy_file "search_history_controller.rb", "app/controllers/search_history_controller.rb"
    end

    def install_saved_searches_controller
      copy_file "saved_searches_controller.rb", "app/controllers/saved_searches_controller.rb"
    end

    def inject_routes
      inject_into_file 'config/routes.rb', after: /mount Blacklight::Engine.*$/ do
        "\n  mount BlacklightAdvancedSearch::Engine => '/'\n"
      end
    end

    def install_localized_search_form
      if options[:force] || yes?("Install local search form with advanced link? (y/N)", :green)
        # We're going to copy the search from from actual currently loaded
        # Blacklight into local app as custom local override -- but add our link at the end too.
        source_file = File.read(File.join(Blacklight.root, "app/views/catalog/_search_form.html.erb"))

        new_file_contents = source_file + <<-EOF.strip_heredoc
        \n\n
        <div class="navbar-form">
          <%= link_to 'More options', blacklight_advanced_search_engine.advanced_search_path(search_state.to_h), class: 'advanced_search btn btn-default'%>
        </div>
        EOF

        create_file("app/views/catalog/_search_form.html.erb", new_file_contents)
      end
    end
  end
end
