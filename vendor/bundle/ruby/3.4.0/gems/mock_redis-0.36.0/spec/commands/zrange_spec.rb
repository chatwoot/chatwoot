require 'spec_helper'

describe '#zrange(key, start, stop [, :with_scores => true])' do
  before do
    @key = 'mock-redis-test:zrange'
    @redises.zadd(@key, 3, 'Jefferson')
    @redises.zadd(@key, 1, 'Washington')
    @redises.zadd(@key, 2, 'Adams')
    @redises.zadd(@key, 4, 'Madison')
  end

  context 'when the zset is empty' do
    before do
      @redises.del(@key)
    end

    it 'should return an empty array' do
      @redises.exists?(@key).should == false
      @redises.zrange(@key, 0, 4).should == []
    end
  end

  it 'returns the elements when the range is given as strings' do
    @redises.zrange(@key, '0', '1').should == %w[Washington Adams]
  end

  it 'returns the elements in order by score' do
    @redises.zrange(@key, 0, 1).should == %w[Washington Adams]
  end

  context 'when a subset of elements have the same score' do
    before do
      @redises.zadd(@key, 1, 'Martha')
    end

    it 'returns the elements in ascending lexicographical order' do
      @redises.zrange(@key, 0, 1).should == %w[Martha Washington]
    end
  end

  it 'returns the elements in order by score (negative indices)' do
    @redises.zrange(@key, -2, -1).should == %w[Jefferson Madison]
  end

  it 'returns empty list when start is too large' do
    @redises.zrange(@key, 5, -1).should == []
  end

  it 'returns entire list when start is out of bounds with negative end in bounds' do
    @redises.zrange(@key, -5, -1).should == %w[Washington Adams Jefferson Madison]
  end

  it 'returns correct subset when start is out of bounds with positive end in bounds' do
    @redises.zrange(@key, -5, 1).should == %w[Washington Adams]
  end

  it 'returns empty list when start is in bounds with negative end out of bounds' do
    @redises.zrange(@key, 1, -5).should == []
  end

  it 'returns empty list when start is 0 with negative end out of bounds' do
    @redises.zrange(@key, 0, -5).should == []
  end

  it 'returns correct subset when start is in bounds with negative end in bounds' do
    @redises.zrange(@key, 1, -1).should == %w[Adams Jefferson Madison]
  end

  it 'returns the scores when :with_scores is specified' do
    @redises.zrange(@key, 0, 1, :with_scores => true).
      should == [['Washington', 1.0], ['Adams', 2.0]]
  end

  it 'returns the scores when :withscores is specified' do
    @redises.zrange(@key, 0, 1, :withscores => true).
      should == [['Washington', 1.0], ['Adams', 2.0]]
  end

  it_should_behave_like 'a zset-only command'
end
