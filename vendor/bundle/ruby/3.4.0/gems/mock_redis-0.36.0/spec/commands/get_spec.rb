require 'spec_helper'

describe '#get(key)' do
  before do
    @key = 'mock-redis-test:73288'
  end

  it 'returns nil for a nonexistent value' do
    @redises.get('mock-redis-test:does-not-exist').should be_nil
  end

  it 'returns a stored string value' do
    @redises.set(@key, 'forsooth')
    @redises.get(@key).should == 'forsooth'
  end

  it 'treats integers as strings' do
    @redises.set(@key, 100)
    @redises.get(@key).should == '100'
  end

  it 'stringifies key' do
    key = :a_symbol

    @redises.set(key, 'hello')
    @redises.get(key.to_s).should == 'hello'
    @redises.get(key).should == 'hello'
  end

  it_should_behave_like 'a string-only command'
end
