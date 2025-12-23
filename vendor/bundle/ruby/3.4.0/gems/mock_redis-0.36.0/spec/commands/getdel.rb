require 'spec_helper'

describe '#getdel(key)' do
  before do
    @key = 'mock-redis-test:73288'
  end

  it 'returns nil for a nonexistent value' do
    @redises.getdel('mock-redis-test:does-not-exist').should be_nil
  end

  it 'returns a stored string value' do
    @redises.set(@key, 'forsooth')
    @redises.getdel(@key).should == 'forsooth'
  end

  it 'deletes the key after returning it' do
    @redises.set(@key, 'forsooth')
    @redises.getdel(@key)
    @redises.get(@key).should be_nil
  end

  it_should_behave_like 'a string-only command'
end
