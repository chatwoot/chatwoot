require 'spec_helper'

describe '#hlen(key)' do
  before do
    @key = 'mock-redis-test:hlen'
    @redises.hset(@key, 'k1', 'v1')
    @redises.hset(@key, 'k2', 'v2')
  end

  it 'returns the number of keys stored in the hash' do
    @redises.hlen(@key).should == 2
  end

  it 'returns [] when there is no such key' do
    @redises.hlen('mock-redis-test:nonesuch').should == 0
  end

  it_should_behave_like 'a hash-only command'
end
