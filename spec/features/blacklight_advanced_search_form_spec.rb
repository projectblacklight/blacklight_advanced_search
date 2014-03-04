require 'spec_helper'

describe "Blacklight Advanced Search Form" do
  before(:all) do
    AdvancedController.copy_blacklight_config_from(CatalogController)
  end

  describe "advanced search form" do
    before do
      visit '/advanced'
    end

    it "should have field and facet blocks" do
      page.should have_selector('.query-criteria')
      page.should have_selector('.limit-criteria')
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
        page.should have_selector '.advanced-search-field #title'
        page.should have_selector '.advanced-search-field #author'
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
      click_on "advanced-search-submit"
      puts page.current_url
      page.should have_content "Remove constraint Title: Medicine"
      page.should have_content "2007020969"
    end
  end

  it "should show the search fields" do
    visit '/advanced'
    page.should have_selector('input#title')
  end
end
