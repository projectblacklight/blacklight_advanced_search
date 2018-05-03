# frozen_string_literal: true

def setFilters(fls)
  @filters = fls
end

## These should be reworked, but attr_reader actually breaks it.
# rubocop:disable Style/TrivialAccessors
def filters
  @filters
end

# rubocop:enable Style/TrivialAccessors
describe "BlacklightAdvancedSearch::FilterParser" do
  include BlacklightAdvancedSearch::FilterParser

  describe "filter processing" do
    it "should generate an appropriate fq param" do
      setFilters(:format => %w(Book Thesis), :location => %w(Online Library))
      fq_params = generate_solr_fq
      expect(fq_params.find { |a| a =~ /format\:\((\"Book\"|\"Thesis\") +OR +(\"Thesis\"|\"Book\")/ }).not_to be_nil
      expect(fq_params.find { |a| a =~ /location\:\((\"Library\"|\"Online\") +OR +(\"Library\"|\"Online\")/ }).not_to be_nil
    end
  end
end
