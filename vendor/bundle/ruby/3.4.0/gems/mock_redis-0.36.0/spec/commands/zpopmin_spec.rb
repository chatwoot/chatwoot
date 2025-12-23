require 'spec_helper'

describe '#zpopmin(key, count)' do
  before(:each) do
    @key = 'mock-redis-test:zpopmin'
    @redises.del(@key)
    @redises.zadd(@key, 1, 'one')
    @redises.zadd(@key, 2, 'two')
    @redises.zadd(@key, 3, 'three')
  end

  context 'when count is unspecified' do
    it 'returns nil if the set does not exist' do
      @redises.zpopmin('does-not-exist').should nil
    end

    it 'returns the lowest ranked element' do
      @redises.zpopmin(@key).should == ['one', 1]
      @redises.zcard(@key).should == 2
    end
  end

  context 'when count is 1' do
    let(:count) { 1 }

    it 'returns nil if the set does not exist' do
      @redises.zpopmin('does-not-exist', count).should nil
    end

    it 'returns the lowest ranked element' do
      @redises.zpopmin(@key, count).should == ['one', 1]
      @redises.zcard(@key).should == 2
    end
  end

  context 'when count is greater than 1' do
    let(:count) { 2 }

    it 'returns empty array if the set does not exist' do
      @redises.zpopmin('does-not-exist', count).should == []
    end

    it 'returns the lowest ranked elements' do
      @redises.zpopmin(@key, count).should == [['one', 1], ['two', 2]]
      @redises.zcard(@key).should == 1
    end
  end

  context 'when count is greater than the size of the set' do
    let(:count) { 4 }

    it 'returns the entire set' do
      before = @redises.zrange(@key, 0, count, with_scores: true)
      @redises.zpopmin(@key, count).should == before
      @redises.zcard(@key).should == 0
    end
  end

  it_should_behave_like 'a zset-only command'
end
