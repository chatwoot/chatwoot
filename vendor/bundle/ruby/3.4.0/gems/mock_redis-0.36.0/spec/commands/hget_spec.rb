require 'spec_helper'

describe '#hget(key, field)' do
  before do
    @key = 'mock-redis-test:hget'
    @redises.hset(@key, 'k1', 'v1')
    @redises.hset(@key, 'k2', 'v2')
  end

  it 'returns the value stored at field' do
    @redises.hget(@key, 'k1').should == 'v1'
  end

  it 'treats the field as a string' do
    @redises.hset(@key, '3', 'v3')
    @redises.hget(@key, 3).should == 'v3'
  end

  it 'returns nil when there is no such field' do
    @redises.hget(@key, 'nonesuch').should be_nil
  end

  it 'returns nil when there is no such key' do
    @redises.hget('mock-redis-test:nonesuch', 'k1').should be_nil
  end

  it_should_behave_like 'a hash-only command'
end
