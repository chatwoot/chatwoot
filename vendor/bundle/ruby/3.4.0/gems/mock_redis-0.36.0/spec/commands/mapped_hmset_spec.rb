require 'spec_helper'

describe '#mapped_hmset(key, hash={})' do
  before do
    @key = 'mock-redis-test:mapped_hmset'
  end

  it "returns 'OK'" do
    @redises.mapped_hmset(@key, 'k1' => 'v1', 'k2' => 'v2').should == 'OK'
  end

  it 'sets the values' do
    @redises.mapped_hmset(@key, 'k1' => 'v1', 'k2' => 'v2')
    @redises.hmget(@key, 'k1', 'k2').should == %w[v1 v2]
  end

  it 'updates an existing hash' do
    @redises.hmset(@key, 'foo', 'bar')
    @redises.mapped_hmset(@key, 'bert' => 'ernie', 'diet' => 'coke')

    @redises.hmget(@key, 'foo', 'bert', 'diet').
      should == %w[bar ernie coke]
  end

  it 'stores the values as strings' do
    @redises.mapped_hmset(@key, 'one' => 1)
    @redises.hget(@key, 'one').should == '1'
  end

  it 'raises an error if given no hash' do
    lambda do
      @redises.mapped_hmset(@key)
    end.should raise_error(ArgumentError)
  end

  it 'raises an error if given a an odd length array' do
    lambda do
      @redises.mapped_hmset(@key, [1])
    end.should raise_error(Redis::CommandError)
  end

  it 'raises an error if given a non-hash value' do
    lambda do
      @redises.mapped_hmset(@key, 1)
    end.should raise_error(NoMethodError)
  end
end
