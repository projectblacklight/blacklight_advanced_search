require 'spec_helper'

describe 'BlacklightAdvancedSearch#deep_merge' do
  let(:hash_X) do
    {
      'a' => 'a',
      'b' => 'b',
      'array1' => [1, 2],
      'array2' => [3, 4],
      'hash1'  => { 'a' => 'a', 'array' => [1], 'b' => 'b' },
      'hash2'  => { 'a2' => 'a2', 'array2' => [12], 'b2' => 'b2' }
    }
  end
  let(:hash_Y) do
    {
      'a' => 'NEW A',
      'c' => 'NEW C',
      'array1' => [3, 4],
      'hash1'  => { 'array' => [2], 'b' => 'NEW B' }
    }
  end
  let(:ahash) do
    BlacklightAdvancedSearch.deep_merge(hash_x, hash_y)
  end

  RSpec.shared_examples 'Mergable Parameters' do # this name referenced below
    it 'does not modify the param hashes' do
      dup_x = hash_x.dup
      dup_y = hash_y.dup
      expect(ahash).not_to eq hash_x # this was the old behavior
      expect(dup_x).to eq hash_x
      expect(dup_y).to eq hash_y
    end

    it 'leaves un-collided content alone' do
      expect(ahash['b']).to eq('b')
      expect(ahash['array2']).to eq([3, 4])
      expect(ahash['hash2']).to eq('a2' => 'a2', 'array2' => [12], 'b2' => 'b2')
    end

    it 'adds new content' do
      expect(ahash['c']).to eq('NEW C')
    end

    it 'merges a hash, recursive like' do
      expect(ahash['hash1']).to eq('a' => 'a', 'array' => [1, 2], 'b' => 'NEW B')
    end

    it 'merges boolean values (false)' do
      expect(BlacklightAdvancedSearch.deep_merge({ a: false }, a: true)).to eq(a: true)
      expect(BlacklightAdvancedSearch.deep_merge({ a: true }, a: false)).to eq(a: false)
    end

    it 'does not merge nil values over existing keys' do
      expect(BlacklightAdvancedSearch.deep_merge({ a: 1 }, a: nil)).to eq(a: 1)
    end

    it 'does merge nil values when the key is not yet present' do
      expect(BlacklightAdvancedSearch.deep_merge({}, a: nil)).to eq(a: nil)
    end

    it 'does not merge empty strings over existing keys' do
      expect(BlacklightAdvancedSearch.deep_merge({ a: 1 }, a: '')).to eq(a: 1)
      expect(BlacklightAdvancedSearch.deep_merge({ a: nil }, a: '')).to eq(a: nil)
    end

    it 'does not merge empty strings when the key is not yet present' do
      expect(BlacklightAdvancedSearch.deep_merge({}, a: '')).to eq(a: '')
    end

    context 'Arrays' do
      it 'merges an array' do
        expect(ahash['array1']).to eq([1, 2, 3, 4])
      end

      it 'collapse to uniq values when merging' do
        expect(BlacklightAdvancedSearch.deep_merge({ a: [1, 1, 2, 1] }, a: [3, 2])).to eq(a: [1, 2, 3])
      end

      it 'does not collapse to uniq values if not merging' do
        expect(BlacklightAdvancedSearch.deep_merge({ a: [1, 1, 2, 1] }, a: [])).to eq(a: [1, 1, 2, 1])
      end
    end
  end

  describe Hash do
    it_behaves_like 'Mergable Parameters' do
      let(:hash_x) { hash_X }
      let(:hash_y) { hash_Y }
    end
  end

  describe HashWithIndifferentAccess do
    it_behaves_like 'Mergable Parameters' do
      let(:hash_x) { hash_X.with_indifferent_access }
      let(:hash_y) { hash_Y.with_indifferent_access }
    end
  end

  describe 'Mixed Hash and HWIA' do
    it_behaves_like 'Mergable Parameters' do
      let(:hash_x) { hash_X }
      let(:hash_y) { hash_Y.with_indifferent_access }
    end

    it_behaves_like 'Mergable Parameters' do
      let(:hash_x) { hash_X.with_indifferent_access }
      let(:hash_y) { hash_Y }
    end
  end

  # from http://apidock.com/rails/v4.2.1/Hash/deep_merge
  describe 'reference example' do
    it 'gives the same result as Rails Hash .deep_merge' do
      h1 = { a: true, b: { c: [1, 2, 3] } }
      h2 = { a: false, b: { x: [3, 4, 5] } }
      merged = { a: false, b: { c: [1, 2, 3], x: [3, 4, 5] } }
      expect(h1.deep_merge(h2)).to eq(merged)
      expect(BlacklightAdvancedSearch.deep_merge(h1, h2)).to eq(merged)
    end
  end
    
end
