require 'spec_helper'

describe '#decr(key)' do
  before { @key = 'mock-redis-test:46895' }

  it 'returns the value after the decrement' do
    @redises.set(@key, 2)
    @redises.decr(@key).should == 1
  end

  it 'treats a missing key like 0' do
    @redises.decr(@key).should == -1
  end

  it 'decrements negative numbers' do
    @redises.set(@key, -10)
    @redises.decr(@key).should == -11
  end

  it 'works multiple times' do
    @redises.decr(@key).should == -1
    @redises.decr(@key).should == -2
    @redises.decr(@key).should == -3
  end

  it 'raises an error if the value does not look like an integer' do
    @redises.set(@key, 'minus one')
    lambda do
      @redises.decr(@key)
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a string-only command'
end
