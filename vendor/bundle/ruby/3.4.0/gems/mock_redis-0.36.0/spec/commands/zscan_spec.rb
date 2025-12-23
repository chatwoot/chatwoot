require 'spec_helper'

describe '#zscan' do
  let(:count) { 10 }
  let(:match) { '*' }
  let(:key) { 'mock-redis-test:zscan' }

  context 'when the zset does not exist' do
    it 'returns a 0 cursor and an empty collection' do
      expect(@redises.zscan(key, 0, count: count, match: match)).to eq(['0', []])
    end
  end

  context 'when the zset exists' do
    before do
      @redises.zadd(key, 1.0, 'member1')
      @redises.zadd(key, 2.0, 'member2')
    end

    it 'returns a 0 cursor and the collection' do
      result = @redises.zscan(key, 0)
      expect(result[0]).to eq('0')
      expect(result[1]).to match_array([['member1', 1.0], ['member2', 2.0]])
    end
  end
end
