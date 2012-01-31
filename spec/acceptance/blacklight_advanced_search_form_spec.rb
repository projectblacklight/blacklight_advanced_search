require 'spec_helper'

describe "Blacklight Advanced Search Form" do
  before do
    AdvancedController.blacklight_config = Blacklight::Configuration.new
    AdvancedController.configure_blacklight do |config|

      config.add_search_field('title') do |field|
        field.solr_local_parameters = { :qf => "title_t", :pf => "title_t"}
      end
    end
  end

  it "should show the search fields" do
    visit '/advanced'
    page.should have_selector('input#title')

  end
end
