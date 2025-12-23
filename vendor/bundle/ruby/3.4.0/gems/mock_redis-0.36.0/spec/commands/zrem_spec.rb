require 'spec_helper'

describe '#zrem(key, member)' do
  before do
    @key = 'mock-redis-test:zrem'

    @redises.zadd(@key, 1, 'one')
    @redises.zadd(@key, 2, 'two')
  end

  it 'returns true if member is present in the set' do
    @redises.zrem(@key, 'one').should == true
  end

  it 'returns false if member is not present in the set' do
    @redises.zrem(@key, 'nobody home').should == false
  end

  it 'removes member from the set' do
    @redises.zrem(@key, 'one')
    @redises.zrange(@key, 0, -1).should == ['two']
  end

  it 'removes integer member from the set' do
    member = 11
    @redises.zadd(@key, 3, member)
    @redises.zrem(@key, member).should == true
    @redises.zrange(@key, 0, -1).should == %w[one two]
  end

  it 'removes integer members inside an array from the set' do
    member = 11
    @redises.zadd(@key, 3, member)
    @redises.zrem(@key, [member]).should == 1
    @redises.zrange(@key, 0, -1).should == %w[one two]
  end

  it 'supports a variable number of arguments' do
    @redises.zrem(@key, %w[one two])
    @redises.zrange(@key, 0, -1).should be_empty
  end

  it 'raises an error if member is an empty array' do
    lambda do
      @redises.zrem(@key, [])
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a zset-only command'
end
