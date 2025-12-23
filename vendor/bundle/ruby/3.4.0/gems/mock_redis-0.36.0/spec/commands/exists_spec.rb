require 'spec_helper'

describe '#exists(*keys)' do
  before { @key1 = 'mock-redis-test:exists1' }
  before { @key2 = 'mock-redis-test:exists2' }

  it 'returns 0 for keys that do not exist' do
    @redises.exists(@key1).should == 0
    @redises.exists(@key1, @key2).should == 0
  end

  it 'returns 1 for keys that do exist' do
    @redises.set(@key1, 1)
    @redises.exists(@key1).should == 1
  end

  it 'returns the count of all keys that exist' do
    @redises.set(@key1, 1)
    @redises.set(@key2, 1)
    @redises.exists(@key1, @key2).should == 2
    @redises.exists(@key1, @key2, 'does-not-exist').should == 2
  end
end

describe '#exists?(*keys)' do
  before { @key1 = 'mock-redis-test:exists1' }
  before { @key2 = 'mock-redis-test:exists2' }

  it 'returns false for keys that do not exist' do
    @redises.exists?(@key1).should == false
    @redises.exists?(@key1, @key2).should == false
  end

  it 'returns true for keys that do exist' do
    @redises.set(@key1, 1)
    @redises.exists?(@key1).should == true
  end

  it 'returns true if any keys exist' do
    @redises.set(@key2, 1)
    @redises.exists?(@key1, @key2).should == true
  end
end
