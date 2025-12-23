require 'spec_helper'

describe '#mset(key, value [, key, value, ...])' do
  before do
    @key1 = 'mock-redis-test:mset1'
    @key2 = 'mock-redis-test:mset2'
  end

  it "responds with 'OK'" do
    @redises.mset(@key1, 1).should == 'OK'
  end

  it "responds with 'OK' for passed Array with 1 item" do
    @redises.mset([@key1, 1]).should == 'OK'
  end

  it "responds with 'OK' for passed Array with 2 items" do
    @redises.mset([@key1, 1, @key2, 2]).should == 'OK'
  end

  it 'sets the values' do
    @redises.mset(@key1, 'value1', @key2, 'value2')
    @redises.mget(@key1, @key2).should == %w[value1 value2]
  end

  it 'raises an error if given an odd number of arguments' do
    lambda do
      @redises.mset(@key1, 'value1', @key2)
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if given 0 arguments' do
    lambda do
      @redises.mset
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if given odd-sized array' do
    lambda do
      @redises.mset([@key1, 1, @key2])
    end.should raise_error(Redis::CommandError)
  end
end
