require 'spec_helper'

describe '#incrbyfloat(key, increment)' do
  before { @key = 'mock-redis-test:65374' }

  it 'returns the value after the increment' do
    @redises.set(@key, 2.0)
    @redises.incrbyfloat(@key, 2.1).should be_within(0.0001).of(4.1)
  end

  it 'treats a missing key like 0' do
    @redises.incrbyfloat(@key, 1.2).should be_within(0.0001).of(1.2)
  end

  it 'increments negative numbers' do
    @redises.set(@key, -10.4)
    @redises.incrbyfloat(@key, 2.3).should be_within(0.0001).of(-8.1)
  end

  it 'works multiple times' do
    @redises.incrbyfloat(@key, 2.1).should be_within(0.0001).of(2.1)
    @redises.incrbyfloat(@key, 2.2).should be_within(0.0001).of(4.3)
    @redises.incrbyfloat(@key, 2.3).should be_within(0.0001).of(6.6)
  end

  it 'accepts an float-ish string' do
    @redises.incrbyfloat(@key, '2.2').should be_within(0.0001).of(2.2)
  end

  it 'raises an error if the value does not look like an float' do
    @redises.set(@key, 'one.two')
    lambda do
      @redises.incrbyfloat(@key, 1)
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if the delta does not look like an float' do
    lambda do
      @redises.incrbyfloat(@key, 'foobar.baz')
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a string-only command'
end
