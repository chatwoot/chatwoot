require 'spec_helper'

describe '#incrby(key, increment)' do
  before { @key = 'mock-redis-test:65374' }

  it 'returns the value after the increment' do
    @redises.set(@key, 2)
    @redises.incrby(@key, 2).should == 4
  end

  it 'treats a missing key like 0' do
    @redises.incrby(@key, 1).should == 1
  end

  it 'increments negative numbers' do
    @redises.set(@key, -10)
    @redises.incrby(@key, 2).should == -8
  end

  it 'works multiple times' do
    @redises.incrby(@key, 2).should == 2
    @redises.incrby(@key, 2).should == 4
    @redises.incrby(@key, 2).should == 6
  end

  it 'accepts an integer-ish string' do
    @redises.incrby(@key, '2').should == 2
  end

  it 'raises an error if the value does not look like an integer' do
    @redises.set(@key, 'one')
    lambda do
      @redises.incrby(@key, 1)
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if the delta does not look like an integer' do
    lambda do
      @redises.incrby(@key, 'foo')
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a string-only command'
end
