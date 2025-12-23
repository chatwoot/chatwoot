require 'spec_helper'

describe '#bitcount(key [, start, end ])' do
  before do
    @key = 'mock-redis-test:bitcount'
    @redises.set(@key, 'foobar')
  end

  it 'gets the number of set bits from the key' do
    @redises.bitcount(@key).should == 26
  end

  it 'gets the number of set bits from the key in an interval' do
    @redises.bitcount(@key, 0, 1000).should == 26
    @redises.bitcount(@key, 0, 0).should == 4
    @redises.bitcount(@key, 1, 1).should == 6
    @redises.bitcount(@key, 1, -2).should == 18
  end

  it 'treats nonexistent keys as empty strings' do
    @redises.bitcount('mock-redis-test:not-found').should == 0
  end

  it_should_behave_like 'a string-only command'
end
