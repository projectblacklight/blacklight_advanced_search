# frozen_string_literal: true

describe 'Blacklight Test Application' do
  it "should have a Blacklight module" do
    expect(Blacklight).to be_a_kind_of(Module)
  end
  it "should have a Catalog controller" do
    expect(CatalogController.blacklight_config).to be_a_kind_of(Blacklight::Configuration)
  end
end
