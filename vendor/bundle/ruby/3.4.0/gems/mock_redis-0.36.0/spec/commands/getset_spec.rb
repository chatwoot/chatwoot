require 'spec_helper'

describe '#getrange(key, value)' do
  before do
    @key = 'mock-redis-test:getset'
    @redises.set(@key, 'oldvalue')
  end

  it 'returns the old value' do
    @redises.getset(@key, 'newvalue').should == 'oldvalue'
  end

  it 'sets the value to the new value' do
    @redises.getset(@key, 'newvalue')
    @redises.get(@key).should == 'newvalue'
  end

  it 'returns nil for nonexistent keys' do
    @redises.getset('mock-redis-test:not-found', 1).should be_nil
  end

  it_should_behave_like 'a string-only command'
end
