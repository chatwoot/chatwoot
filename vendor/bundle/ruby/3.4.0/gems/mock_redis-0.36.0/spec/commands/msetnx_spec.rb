require 'spec_helper'

describe '#msetnx(key, value [, key, value, ...])' do
  before do
    @key1 = 'mock-redis-test:msetnx1'
    @key2 = 'mock-redis-test:msetnx2'
  end

  it 'responds with 1 if any keys were set' do
    @redises.msetnx(@key1, 1).should == true
  end

  it 'sets the values' do
    @redises.msetnx(@key1, 'value1', @key2, 'value2')
    @redises.mget(@key1, @key2).should == %w[value1 value2]
  end

  it 'does nothing if any value is already set' do
    @redises.set(@key1, 'old1')
    @redises.msetnx(@key1, 'value1', @key2, 'value2')
    @redises.mget(@key1, @key2).should == ['old1', nil]
  end

  it 'responds with 0 if any value is already set' do
    @redises.set(@key1, 'old1')
    @redises.msetnx(@key1, 'value1', @key2, 'value2').should == false
  end

  it 'raises an error if given an odd number of arguments' do
    lambda do
      @redises.msetnx(@key1, 'value1', @key2)
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if given 0 arguments' do
    lambda do
      @redises.msetnx
    end.should raise_error(Redis::CommandError)
  end
end
