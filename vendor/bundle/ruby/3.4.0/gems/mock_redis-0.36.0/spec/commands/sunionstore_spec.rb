require 'spec_helper'

describe '#sunionstore(destination, key [, key, ...])' do
  before do
    @evens       = 'mock-redis-test:sunionstore:evens'
    @primes      = 'mock-redis-test:sunionstore:primes'
    @destination = 'mock-redis-test:sunionstore:destination'

    [2, 4, 6, 8, 10].each { |i| @redises.sadd(@evens, i) }
    [2, 3, 5, 7].each { |i| @redises.sadd(@primes, i) }
  end

  it 'returns the number of elements in the resulting set' do
    @redises.sunionstore(@destination, @primes, @evens).should == 8
  end

  it 'stores the resulting set' do
    @redises.sunionstore(@destination, @primes, @evens)
    @redises.smembers(@destination).should == %w[10 8 6 4 7 5 3 2]
  end

  it 'does not store empty sets' do
    @redises.sunionstore(@destination,
      'mock-redis-test:nonesuch',
      'mock-redis-test:nonesuch2').should == 0
    @redises.get(@destination).should be_nil
  end

  it 'removes existing elements in destination' do
    @redises.sadd(@destination, 42)

    @redises.sunionstore(@destination, @primes)
    @redises.smembers(@destination).should == %w[7 5 3 2]
  end

  it 'correctly unions and stores when the destination is empty and is one of the arguments' do
    @redises.sunionstore(@destination, @destination, @primes)

    @redises.smembers(@destination).should == %w[7 5 3 2]
  end

  it 'raises an error if given 0 sets' do
    lambda do
      @redises.sunionstore(@destination)
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if any argument is not a a set' do
    @redises.set('mock-redis-test:notset', 1)

    lambda do
      @redises.sunionstore(@destination, @primes, 'mock-redis-test:notset')
    end.should raise_error(Redis::CommandError)

    lambda do
      @redises.sunionstore(@destination, 'mock-redis-test:notset', @primes)
    end.should raise_error(Redis::CommandError)
  end
end
