require 'spec_helper'

describe '#hexists(key, field)' do
  before do
    @key = 'mock-redis-test:hexists'
    @redises.hset(@key, 'field', 'value')
  end

  it 'returns true if the hash has that field' do
    @redises.hexists(@key, 'field').should == true
  end

  it 'returns false if the hash lacks that field' do
    @redises.hexists(@key, 'nonesuch').should == false
  end

  it 'treats the field as a string' do
    @redises.hset(@key, 1, 'one')
    @redises.hexists(@key, 1).should == true
  end

  it 'returns nil when there is no such key' do
    @redises.hexists('mock-redis-test:nonesuch', 'key').should == false
  end

  it_should_behave_like 'a hash-only command'
end
