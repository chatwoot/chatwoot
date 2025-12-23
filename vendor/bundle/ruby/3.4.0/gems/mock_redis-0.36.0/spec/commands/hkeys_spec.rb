require 'spec_helper'

describe '#hkeys(key)' do
  before do
    @key = 'mock-redis-test:hkeys'
    @redises.hset(@key, 'k1', 'v1')
    @redises.hset(@key, 'k2', 'v2')
  end

  it 'returns the keys stored in the hash' do
    @redises.hkeys(@key).sort.should == %w[k1 k2]
  end

  it 'returns [] when there is no such key' do
    @redises.hkeys('mock-redis-test:nonesuch').should == []
  end

  it_should_behave_like 'a hash-only command'
end
