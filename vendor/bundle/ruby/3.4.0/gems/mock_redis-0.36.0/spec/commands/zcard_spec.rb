require 'spec_helper'

describe '#zcard(key)' do
  before do
    @key = 'mock-redis-test:zcard'
  end

  it 'returns the number of elements in the zset' do
    @redises.zadd(@key, 1, 'Washington')
    @redises.zadd(@key, 2, 'Adams')
    @redises.zcard(@key).should == 2
  end

  it 'returns 0 for nonexistent sets' do
    @redises.zcard(@key).should == 0
  end

  it_should_behave_like 'a zset-only command'
end
