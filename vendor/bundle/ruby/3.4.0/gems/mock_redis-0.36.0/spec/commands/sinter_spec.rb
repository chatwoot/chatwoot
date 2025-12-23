require 'spec_helper'

describe '#sinter(key [, key, ...])' do
  before do
    @numbers = 'mock-redis-test:sinter:numbers'
    @evens   = 'mock-redis-test:sinter:evens'
    @primes  = 'mock-redis-test:sinter:primes'

    (1..10).each { |i| @redises.sadd(@numbers, i) }
    [2, 4, 6, 8, 10].each { |i| @redises.sadd(@evens, i) }
    [2, 3, 5, 7].each { |i| @redises.sadd(@primes, i) }
  end

  it 'returns the elements in the resulting set' do
    @redises.sinter(@evens, @primes).should == ['2']
  end

  it 'treats missing keys as empty sets' do
    @redises.sinter(@destination, 'mock-redis-test:nonesuch').should == []
  end

  it 'raises an error if given 0 sets' do
    lambda do
      @redises.sinter
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if any argument is not a a set' do
    @redises.set('mock-redis-test:notset', 1)

    lambda do
      @redises.sinter(@numbers, 'mock-redis-test:notset')
    end.should raise_error(Redis::CommandError)

    lambda do
      @redises.sinter('mock-redis-test:notset', @numbers)
    end.should raise_error(Redis::CommandError)
  end
end
