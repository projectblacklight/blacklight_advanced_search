describe "Blacklight Advanced Search Form" do
  before(:all) do
    AdvancedController.copy_blacklight_config_from(CatalogController)
  end

  describe "advanced search form" do
    before do
      visit '/advanced?hypothetical_existing_param=true&q=ignore+this+existing+query'
    end

    it "should have field and facet blocks" do
      expect(page).to have_selector('.query-criteria')
      expect(page).to have_selector('.limit-criteria')
    end

    describe "query column" do
      it "should give the user a choice between and/or queries" do
        expect(page).to have_selector('#op')
        within('#op') do
          expect(page).to have_selector('option[value="AND"]')
          expect(page).to have_selector('option[value="OR"]')
        end
      end

      it "should list the configured search fields" do
        expect(page).to have_selector '.advanced-search-field #title'
        expect(page).to have_selector '.advanced-search-field #author'
      end

      it "should not list the search fields listed as not to be included in adv search" do
        expect(page).not_to have_selector '.advanced_search_field #dummy_field'
      end
    end

    describe "facet column" do
      it "should list facets" do
        expect(page).to have_selector('.blacklight-language_facet')

        within('.blacklight-language_facet') do
          expect(page).to have_content "Language Facet"
        end
      end
    end

    it "scope searches to fields" do
      fill_in "title", :with => "Medicine"
      click_on "advanced-search-submit"
      expect(page).to have_content "Remove constraint Title: Medicine"
      expect(page).to have_content "2007020969"
    end
  end

  it "should show the search fields" do
    visit '/advanced'
    expect(page).to have_selector('input#title')
  end
end
