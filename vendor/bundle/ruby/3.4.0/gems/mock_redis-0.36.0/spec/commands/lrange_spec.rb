require 'spec_helper'

describe '#lrange(key, start, stop)' do
  before do
    @key = 'mock-redis-test:68036'

    @redises.lpush(@key, 'v4')
    @redises.lpush(@key, 'v3')
    @redises.lpush(@key, 'v2')
    @redises.lpush(@key, 'v1')
    @redises.lpush(@key, 'v0')
  end

  it 'returns a subset of the list inclusive of the right end' do
    @redises.lrange(@key, 0, 2).should == %w[v0 v1 v2]
  end

  it 'returns a subset of the list when start and end are strings' do
    @redises.lrange(@key, '0', '2').should == %w[v0 v1 v2]
  end

  it 'returns an empty list when start > end' do
    @redises.lrange(@key, 3, 2).should == []
  end

  it 'works with a negative stop index' do
    @redises.lrange(@key, 2, -1).should == %w[v2 v3 v4]
  end

  it 'works with negative start and stop indices' do
    @redises.lrange(@key, -2, -1).should == %w[v3 v4]
  end

  it 'works with negative start indices less than list length' do
    @redises.lrange(@key, -10, -2).should == %w[v0 v1 v2 v3]
  end

  it 'returns [] when run against a nonexistent value' do
    @redises.lrange('mock-redis-test:bogus-key', 0, 1).should == []
  end

  it 'returns [] when start is too large' do
    @redises.lrange(@key, 100, 100).should == []
  end

  it 'finds the end of the list correctly when end is too large' do
    @redises.lrange(@key, 4, 10).should == %w[v4]
  end

  it_should_behave_like 'a list-only command'
end
