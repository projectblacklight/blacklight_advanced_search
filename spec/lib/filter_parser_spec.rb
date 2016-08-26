def setFilters(f)
  @filters = f
end

def filters
  @filters
end

describe "BlacklightAdvancedSearch::FilterParser" do
  include BlacklightAdvancedSearch::FilterParser

  describe "filter processing" do
    it "should generate an appropriate fq param" do
      setFilters(:format => ["Book", "Thesis"], :location=>["Online", "Library"])
      fq_params = generate_solr_fq
      expect(fq_params.find {|a| a =~ /format\:\((\"Book\"|\"Thesis\") +OR +(\"Thesis\"|\"Book\")/}).not_to be_nil
      expect(fq_params.find {|a| a =~ /location\:\((\"Library\"|\"Online\") +OR +(\"Library\"|\"Online\")/}).not_to be_nil
    end
  end
end
