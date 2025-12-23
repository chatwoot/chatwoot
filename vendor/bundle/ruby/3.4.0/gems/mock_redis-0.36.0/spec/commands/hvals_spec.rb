require 'spec_helper'

describe '#hvals(key)' do
  before do
    @key = 'mock-redis-test:hvals'
    @redises.hset(@key, 'k1', 'v1')
    @redises.hset(@key, 'k2', 'v2')
  end

  it 'returns the values stored in the hash' do
    @redises.hvals(@key).sort.should == %w[v1 v2]
  end

  it 'returns [] when there is no such key' do
    @redises.hvals('mock-redis-test:nonesuch').should == []
  end

  it_should_behave_like 'a hash-only command'
end
