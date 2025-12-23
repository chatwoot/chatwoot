require 'spec_helper'

describe '#hincrbyfloat(key, field, increment)' do
  before do
    @key = 'mock-redis-test:hincrbyfloat'
    @field = 'count'
  end

  it 'returns the value after the increment' do
    @redises.hset(@key, @field, 2.0)
    @redises.hincrbyfloat(@key, @field, 2.1).should be_within(0.0001).of(4.1)
  end

  it 'treats a missing key like 0' do
    @redises.hincrbyfloat(@key, @field, 1.2).should be_within(0.0001).of(1.2)
  end

  it 'creates a hash if nothing is present' do
    @redises.hincrbyfloat(@key, @field, 1.0)
    @redises.hget(@key, @field).should == '1'
  end

  it 'increments negative numbers' do
    @redises.hset(@key, @field, -10.4)
    @redises.hincrbyfloat(@key, @field, 2.3).should be_within(0.0001).of(-8.1)
  end

  it 'works multiple times' do
    @redises.hincrbyfloat(@key, @field, 2.1).should be_within(0.0001).of(2.1)
    @redises.hincrbyfloat(@key, @field, 2.2).should be_within(0.0001).of(4.3)
    @redises.hincrbyfloat(@key, @field, 2.3).should be_within(0.0001).of(6.6)
  end

  it 'accepts a float-ish string' do
    @redises.hincrbyfloat(@key, @field, '2.2').should be_within(0.0001).of(2.2)
  end

  it 'treats the field as a string' do
    field = 11
    @redises.hset(@key, field, 2)
    @redises.hincrbyfloat(@key, field, 2).should == 4.0
  end

  it 'raises an error if the value does not look like a float' do
    @redises.hset(@key, @field, 'one.two')
    lambda do
      @redises.hincrbyfloat(@key, @field, 1)
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if the delta does not look like a float' do
    lambda do
      @redises.hincrbyfloat(@key, @field, 'foobar.baz')
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a hash-only command'
end
