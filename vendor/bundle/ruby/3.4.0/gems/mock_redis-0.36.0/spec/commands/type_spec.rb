require 'spec_helper'

describe '#type(key)' do
  before do
    @key = 'mock-redis-test:type'
  end

  it "returns 'none' for no key" do
    @redises.type(@key).should == 'none'
  end

  it "returns 'string' for a string" do
    @redises.set(@key, 'stringlish')
    @redises.type(@key).should == 'string'
  end

  it "returns 'list' for a list" do
    @redises.lpush(@key, 100)
    @redises.type(@key).should == 'list'
  end

  it "returns 'hash' for a hash" do
    @redises.hset(@key, 100, 200)
    @redises.type(@key).should == 'hash'
  end

  it "returns 'set' for a set" do
    @redises.sadd(@key, 100)
    @redises.type(@key).should == 'set'
  end

  it "returns 'zset' for a zset" do
    @redises.zadd(@key, 1, 2)
    @redises.type(@key).should == 'zset'
  end
end
