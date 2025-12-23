require 'spec_helper'

describe '#hincrby(key, field, increment)' do
  before do
    @key = 'mock-redis-test:hincrby'
    @field = 'count'
  end

  it 'returns the value after the increment' do
    @redises.hset(@key, @field, 2)
    @redises.hincrby(@key, @field, 2).should == 4
  end

  it 'treats a missing key like 0' do
    @redises.hincrby(@key, @field, 1).should == 1
  end

  it 'creates a hash if nothing is present' do
    @redises.hincrby(@key, @field, 1)
    @redises.hget(@key, @field).should == '1'
  end

  it 'increments negative numbers' do
    @redises.hset(@key, @field, -10)
    @redises.hincrby(@key, @field, 2).should == -8
  end

  it 'works multiple times' do
    @redises.hincrby(@key, @field, 2).should == 2
    @redises.hincrby(@key, @field, 2).should == 4
    @redises.hincrby(@key, @field, 2).should == 6
  end

  it 'accepts an integer-ish string' do
    @redises.hincrby(@key, @field, '2').should == 2
  end

  it 'treats the field as a string' do
    field = 11
    @redises.hset(@key, field, 2)
    @redises.hincrby(@key, field, 2).should == 4
  end

  it 'raises an error if the value does not look like an integer' do
    @redises.hset(@key, @field, 'one')
    lambda do
      @redises.hincrby(@key, @field, 1)
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if the delta does not look like an integer' do
    lambda do
      @redises.hincrby(@key, @field, 'foo')
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a hash-only command'
end
