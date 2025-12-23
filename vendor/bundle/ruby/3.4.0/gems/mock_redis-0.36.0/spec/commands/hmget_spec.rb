require 'spec_helper'

describe '#hmget(key, field [, field, ...])' do
  before do
    @key = 'mock-redis-test:hmget'
    @redises.hset(@key, 'k1', 'v1')
    @redises.hset(@key, 'k2', 'v2')
  end

  it 'returns the values for those keys' do
    @redises.hmget(@key, 'k1', 'k2').sort.should == %w[v1 v2]
  end

  it 'treats an array as multiple keys' do
    @redises.hmget(@key, %w[k1 k2]).sort.should == %w[v1 v2]
  end

  it 'treats the fielsd as strings' do
    @redises.hset(@key, 1, 'one')
    @redises.hset(@key, 2, 'two')
    @redises.hmget(@key, 1, 2).sort.should == %w[one two]
  end

  it 'returns nils when there are no such fields' do
    @redises.hmget(@key, 'k1', 'mock-redis-test:nonesuch').
      should == ['v1', nil]
  end

  it 'returns nils when there is no such key' do
    @redises.hmget(@key, 'mock-redis-test:nonesuch').should == [nil]
  end

  it 'raises an error if given no fields' do
    lambda do
      @redises.hmget(@key)
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if given an empty list of fields' do
    lambda do
      @redises.hmget(@key, [])
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a hash-only command'
end
