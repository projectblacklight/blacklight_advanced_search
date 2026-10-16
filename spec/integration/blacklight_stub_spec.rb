# frozen_string_literal: true

describe 'Blacklight Test Application' do
  it 'has a Blacklight module' do
    expect(Blacklight).to be_a(Module)
  end

  it 'has a Catalog controller' do
    expect(CatalogController.blacklight_config).to be_a(Blacklight::Configuration)
  end
end
