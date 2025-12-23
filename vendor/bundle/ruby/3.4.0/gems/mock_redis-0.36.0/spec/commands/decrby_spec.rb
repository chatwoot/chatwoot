require 'spec_helper'

describe '#decrby(key, decrement)' do
  before { @key = 'mock-redis-test:43650' }

  it 'returns the value after the decrement' do
    @redises.set(@key, 4)
    @redises.decrby(@key, 2).should == 2
  end

  it 'treats a missing key like 0' do
    @redises.decrby(@key, 2).should == -2
  end

  it 'decrements negative numbers' do
    @redises.set(@key, -10)
    @redises.decrby(@key, 2).should == -12
  end

  it 'works multiple times' do
    @redises.decrby(@key, 2).should == -2
    @redises.decrby(@key, 2).should == -4
    @redises.decrby(@key, 2).should == -6
  end

  it 'raises an error if the value does not look like an integer' do
    @redises.set(@key, 'one')
    lambda do
      @redises.decrby(@key, 1)
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a string-only command'
end
