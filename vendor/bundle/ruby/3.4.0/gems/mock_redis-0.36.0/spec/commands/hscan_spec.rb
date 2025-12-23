require 'spec_helper'

describe '#hscan' do
  let(:count) { 10 }
  let(:match) { '*' }
  let(:key) { 'mock-redis-test:hscan' }

  context 'when the hash does not exist' do
    it 'returns a 0 cursor and an empty collection' do
      expect(@redises.hscan(key, 0, count: count, match: match)).to eq(['0', []])
    end
  end

  context 'when the hash exists' do
    before do
      @redises.hset(key, 'k1', 'v1')
      @redises.hset(key, 'k2', 'v2')
      @redises.hset(key, 'k3', 'v3')
    end

    let(:expected) { ['0', [%w[k1 v1], %w[k2 v2], %w[k3 v3]]] }

    it 'returns a 0 cursor and the collection' do
      expect(@redises.hscan(key, 0, count: 10)).to eq(expected)
    end
  end
end
