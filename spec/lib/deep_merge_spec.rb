require 'spec_helper'

describe "BlacklightAdvancedSearch#deep_merge!" do
  before do
    @ahash = {"a" => "a", "b" => "b", 
            "array1" => [1,2], "array2" => [3,4],
            "hash1"  => {"a" => "a", "array" => [1], "b" => "b"},
            "hash2"  => {"a2" => "a2", "array2" => [12], "b2" => "b2"}
    }

    BlacklightAdvancedSearch.deep_merge!(@ahash, {
      "a" => "NEW A",
      "array1" => [3, 4],
      "hash1"  => {
        "array" => [2],
        "b" => "NEW B"
      },
      "c" => "NEW C"
    })
  end


  it "leaves un-collided content alone" do
    expect(@ahash["b"]).to eq("b")
    expect(@ahash["array2"]).to eq([3,4])
    expect(@ahash["hash2"]).to eq({"a2" => "a2", "array2" => [12], "b2" => "b2"})
  end

  it "adds new content" do
    expect(@ahash["c"]).to eq("NEW C")
  end

  it "merges an array" do
    expect(@ahash["array1"]).to eq([1,2,3,4])
  end

  it "merges a hash, recursive like" do
    expect(@ahash["hash1"]).to eq({
      "a" => "a",
      "array" => [1,2],
      "b" => "NEW B"
    })
  end
    
end