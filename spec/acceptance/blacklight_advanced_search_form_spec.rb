require 'spec_helper'

describe "Blacklight Advanced Search Form" do
  before(:all) do
    CatalogController.configure_blacklight do |config|
      config.default_solr_params = { 
        :qt => 'search',
        :rows => 10 
      }

      config.add_facet_field 'language_facet'

      config.add_search_field('title') do |field|
        field.solr_local_parameters = { :qf => "title_t", :pf => "title_t"}
      end

      config.add_search_field('author') do |field|
        field.solr_local_parameters = { :qf => "author_t", :pf => "author_t"}
      end

      config.add_search_field('dummy_field') do |field|
        field.include_in_advanced_search = false
        field.solr_local_parameters = { :qf => "author_t", :pf => "author_t"}
      end
    end
    AdvancedController.copy_blacklight_config_from(CatalogController)
  end

  describe "advanced search form" do
    before do
      visit '/advanced'
    end

    it "should have field and facet blocks" do
      page.should have_selector('.query_column')
      page.should have_selector('.limit_column')
    end

    describe "query column" do
      it "should give the user a choice between and/or queries" do
        page.should have_selector('#op')
        within('#op') do
          page.should have_selector('option[value="AND"]')
          page.should have_selector('option[value="OR"]')
        end
      end

      it "should list the configured search fields" do
        page.should have_selector '.advanced_search_field #title'
        page.should have_selector '.advanced_search_field #author'
      end

      it "should not list the search fields listed as not to be included in adv search" do
        page.should_not have_selector '.advanced_search_field #dummy_field'
      end
    end

    describe "facet column" do
      it "should list facets" do
        page.should have_selector('.blacklight-language_facet')

        within('.blacklight-language_facet') do
          page.should have_content "Language Facet"
        end
      end
    end

    it "scope searches to fields" do
      fill_in "title", :with => "Medicine"
      click_on "Search"
      page.should have_content "Remove constraint Title: Medicine"
      page.should have_content "2007020969"
    end
  end

  it "should show the search fields" do
    visit '/advanced'
    page.should have_selector('input#title')
  end
end
