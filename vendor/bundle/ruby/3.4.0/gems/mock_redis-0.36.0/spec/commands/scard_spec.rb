require 'spec_helper'

describe '#scard(key)' do
  before { @key = 'mock-redis-test:scard' }

  it 'returns 0 for an empty set' do
    @redises.scard(@key).should == 0
  end

  it 'returns the number of elements in the set' do
    @redises.sadd(@key, 'one')
    @redises.sadd(@key, 'two')
    @redises.sadd(@key, 'three')
    @redises.scard(@key).should == 3
  end

  it_should_behave_like 'a set-only command'
end
