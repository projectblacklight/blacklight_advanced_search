require 'rails/generators'

module BlacklightAdvancedSearch
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def inject_search_builder
      inject_into_file 'app/models/search_builder.rb', after: /include Blacklight::Solr::SearchBuilderBehavior.*$/ do
        "\n  include BlacklightAdvancedSearch::AdvancedSearchBuilder" \
        "\n  self.default_processor_chain += [:add_advanced_parse_q_to_solr, :add_advanced_search_to_solr]"
      end
    end

    def configuration
      inject_into_file 'app/controllers/catalog_controller.rb', after: "configure_blacklight do |config|" do
        "\n    # default advanced config values" \
        "\n    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new" \
        "\n    config.advanced_search[:enabled] = true" \
        "\n    config.advanced_search[:form_solr_paramters] = {}" \
        "\n    # config.advanced_search[:qt] ||= 'advanced'" \
        "\n    config.advanced_search[:query_parser] ||= 'dismax'"
      end
    end

    def inject_routes
      inject_into_file 'config/routes.rb', after: /mount Blacklight::Engine.*$/ do
        "\n  mount BlacklightAdvancedSearch::Engine => '/'\n"
      end
    end
  end
end
