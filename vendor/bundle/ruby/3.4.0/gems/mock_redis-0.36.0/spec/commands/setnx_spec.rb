require 'spec_helper'

describe '#setnx(key, value)' do
  before { @key = 'mock-redis-test:setnx' }

  it 'returns true if the key was absent' do
    @redises.setnx(@key, 1).should == true
  end

  it 'returns false if the key was present' do
    @redises.set(@key, 2)
    @redises.setnx(@key, 1).should == false
  end

  it 'sets the value if missing' do
    @redises.setnx(@key, 'value')
    @redises.get(@key).should == 'value'
  end

  it 'does nothing if the value is present' do
    @redises.set(@key, 'old')
    @redises.setnx(@key, 'new')
    @redises.get(@key).should == 'old'
  end
end
