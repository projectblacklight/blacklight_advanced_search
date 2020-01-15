# frozen_string_literal: true

describe 'Blacklight Advanced Search Form' do
  before(:all) do
    AdvancedController.copy_blacklight_config_from(CatalogController)
  end

  describe 'advanced search form' do
    before do
      visit '/advanced?hypothetical_existing_param=true&q=ignore+this+existing+query'
    end

    it 'has field and facet blocks' do
      expect(page).to have_selector('.query-criteria')
      expect(page).to have_selector('.limit-criteria')
    end

    describe 'query column' do
      it 'gives the user a choice between and/or queries' do
        expect(page).to have_selector('#op')
        within('#op') do
          expect(page).to have_selector('option[value="AND"]')
          expect(page).to have_selector('option[value="OR"]')
        end
      end

      it 'lists the configured search fields' do
        expect(page).to have_selector '.advanced-search-field #title'
        expect(page).to have_selector '.advanced-search-field #author'
      end

      it 'does not list the search fields listed as not to be included in adv search' do
        expect(page).not_to have_selector '.advanced_search_field #dummy_field'
      end
    end

    describe 'facet column' do
      it 'lists facets' do
        expect(page).to have_selector('.blacklight-language_ssim')

        within('.blacklight-language_ssim') do
          expect(page).to have_content 'Language Ssim'
        end
      end
    end

    it 'scope searches to fields' do
      fill_in 'title', with: 'Medicine'
      click_on 'advanced-search-submit'
      expect(page).to have_content 'Remove constraint Title: Medicine'
      expect(page).to have_content '2007020969'
    end
  end

  it 'shows the search fields' do
    visit '/advanced'
    expect(page).to have_selector('input#title')
  end

  describe 'prepopulated advanced search form' do
    before do
      visit '/advanced?all_fields=&author=&commit=Search&op=AND&search_field=advanced&title=cheese'
    end

    it 'does not create hidden inputs for search fields' do
      expect(page).not_to have_selector('.advanced input[type="hidden"][name="title"]', visible: false)
      expect(page).to have_selector('.advanced input[type="text"][name="title"]')
    end

    it 'does not have multiple parameters for a search field' do
      fill_in 'title', with: 'bread'
      click_on 'advanced-search-submit'
      expect(page.current_url).to match(/bread/)
      expect(page.current_url).not_to match(/cheese/)
    end
  end
end
