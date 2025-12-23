require 'spec_helper'

describe '#lset(key, index, value)' do
  before do
    @key = 'mock-redis-test:21522'

    @redises.lpush(@key, 'v1')
    @redises.lpush(@key, 'v0')
  end

  it "returns 'OK'" do
    @redises.lset(@key, 0, 'newthing').should == 'OK'
  end

  it "sets the list's value at index to value" do
    @redises.lset(@key, 0, 'newthing')
    @redises.lindex(@key, 0).should == 'newthing'
  end

  it "sets the list's value at index to value when the index is a string" do
    @redises.lset(@key, '0', 'newthing')
    @redises.lindex(@key, 0).should == 'newthing'
  end

  it 'stringifies value' do
    @redises.lset(@key, 0, 12_345)
    @redises.lindex(@key, 0).should == '12345'
  end

  it 'raises an exception for nonexistent keys' do
    lambda do
      @redises.lset('mock-redis-test:bogus-key', 100, 'value')
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an exception for out-of-range indices' do
    lambda do
      @redises.lset(@key, 100, 'value')
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a list-only command'
end
