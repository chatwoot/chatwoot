require 'spec_helper'

describe '#sscan' do
  let(:count) { 10 }
  let(:match) { '*' }
  let(:key) { 'mock-redis-test:sscan' }

  before do
    # The return order of the members is non-deterministic, so we sort them to compare
    expect_any_instance_of(Redis).to receive(:sscan).and_wrap_original do |m, *args|
      result = m.call(*args)
      [result[0], result[1].sort]
    end
    expect_any_instance_of(MockRedis).to receive(:sscan).and_wrap_original do |m, *args|
      result = m.call(*args)
      [result[0], result[1].sort]
    end
  end

  context 'when the set does not exist' do
    it 'returns a 0 cursor and an empty collection' do
      expect(@redises.sscan(key, 0, count: count, match: match)).to eq(['0', []])
    end
  end

  context 'when the set exists' do
    before do
      @redises.sadd(key, 'Hello')
      @redises.sadd(key, 'World')
      @redises.sadd(key, 'Test')
    end

    let(:expected) { ['0', %w[Hello Test World]] }

    it 'returns a 0 cursor and the collection' do
      expect(@redises.sscan(key, 0, count: count)).to eq(expected)
    end
  end
end
