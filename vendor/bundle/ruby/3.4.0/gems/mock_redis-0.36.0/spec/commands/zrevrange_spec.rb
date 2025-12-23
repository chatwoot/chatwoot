require 'spec_helper'

describe '#zrevrange(key, start, stop [, :with_scores => true])' do
  before do
    @key = 'mock-redis-test:zrevrange'
    @redises.zadd(@key, 1, 'Washington')
    @redises.zadd(@key, 2, 'Adams')
    @redises.zadd(@key, 3, 'Jefferson')
    @redises.zadd(@key, 4, 'Madison')
  end

  context 'when the zset is empty' do
    before do
      @redises.del(@key)
    end

    it 'should return an empty array' do
      @redises.exists?(@key).should == false
      @redises.zrevrange(@key, 0, 4).should == []
    end
  end

  it 'returns the elements in order by score' do
    @redises.zrevrange(@key, 0, 1).should == %w[Madison Jefferson]
  end

  context 'when a subset of elements have the same score' do
    before do
      @redises.zadd(@key, 1, 'Martha')
    end

    it 'returns the elements in descending lexicographical order' do
      @redises.zrevrange(@key, 3, 4).should == %w[Washington Martha]
    end
  end

  it 'returns the elements in order by score (negative indices)' do
    @redises.zrevrange(@key, -2, -1).should == %w[Adams Washington]
  end

  it 'returns empty list when start is too large' do
    @redises.zrevrange(@key, 5, -1).should == []
  end

  it 'returns the scores when :with_scores is specified' do
    @redises.zrevrange(@key, 2, 3, :with_scores => true).
      should == [['Adams', 2.0], ['Washington', 1.0]]
  end

  it 'returns the scores when :withscores is specified' do
    @redises.zrevrange(@key, 2, 3, :withscores => true).
      should == [['Adams', 2.0], ['Washington', 1.0]]
  end

  it_should_behave_like 'a zset-only command'
end
