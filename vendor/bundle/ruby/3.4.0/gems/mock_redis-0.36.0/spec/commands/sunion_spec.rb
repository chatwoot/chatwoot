require 'spec_helper'

describe '#sunion(key [, key, ...])' do
  before do
    @evens   = 'mock-redis-test:sunion:evens'
    @primes  = 'mock-redis-test:sunion:primes'

    [2, 4, 6, 8, 10].each { |i| @redises.sadd(@evens, i) }
    [2, 3, 5, 7].each { |i| @redises.sadd(@primes, i) }
  end

  it 'returns the elements in the resulting set' do
    @redises.sunion(@evens, @primes).should == %w[2 4 6 8 10 3 5 7]
  end

  it 'treats missing keys as empty sets' do
    @redises.sunion(@primes, 'mock-redis-test:nonesuch').
      should == %w[2 3 5 7]
  end

  it 'allows Array as argument' do
    @redises.sunion([@evens, @primes]).should == %w[2 4 6 8 10 3 5 7]
  end

  it 'raises an error if given 0 sets' do
    lambda do
      @redises.sunion
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if any argument is not a a set' do
    @redises.set('mock-redis-test:notset', 1)

    lambda do
      @redises.sunion(@numbers, 'mock-redis-test:notset')
    end.should raise_error(Redis::CommandError)

    lambda do
      @redises.sunion('mock-redis-test:notset', @numbers)
    end.should raise_error(Redis::CommandError)
  end
end
