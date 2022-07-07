describe "Blacklight Advanced Search Form" do
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
          expect(page).to have_selector('option[value="must"]')
          expect(page).to have_selector('option[value="should"]')
        end
      end

      it "should list the configured search fields" do
        expect(page).to have_field 'Title'
        expect(page).to have_field 'Author'
      end

      it "should not list the search fields listed as not to be included in adv search" do
        expect(page).not_to have_field 'Dummy field'
      end
    end

    describe "facet column" do
      it "should list facets" do
        expect(page).to have_selector('.blacklight-language_ssim')

        within('.blacklight-language_ssim') do
          expect(page).to have_content "Language Ssim"
        end
      end
    end

    it "scope searches to fields" do
      fill_in "Title", :with => "Medicine"
      click_on "advanced-search-submit"
      expect(page).to have_content "Remove constraint Title: Medicine"
      expect(page).to have_content "2007020969"
    end
  end

  it "should show the search fields" do
    visit '/advanced'
    expect(page).to have_field 'Title'
  end

  describe "prepopulated advanced search form" do
    before do
      visit '/advanced?clause[0][field]=title&clause[0][query]=cheese'
    end

    it "should not create hidden inputs for search fields" do
      expect(page).to have_field 'Title', with: 'cheese'
    end

    it "should not have multiple parameters for a search field" do
      fill_in "Title", :with => "bread"
      click_on "advanced-search-submit"
      expect(page.current_url).to match(/bread/)
      expect(page.current_url).not_to match(/cheese/)
    end
  end
end
