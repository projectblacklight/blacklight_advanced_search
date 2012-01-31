require 'spec_helper'

describe 'Blacklight Test Application' do
  it "should have a Blacklight module" do
    Blacklight.should be_a_kind_of(Module)
  end
  it "should have a Catalog controller" do
    CatalogController.blacklight_config.should be_a_kind_of(Blacklight::Configuration)
  end
end
