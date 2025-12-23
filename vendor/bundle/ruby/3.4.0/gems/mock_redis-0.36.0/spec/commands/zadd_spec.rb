require 'spec_helper'

describe '#zadd(key, score, member)' do
  before { @key = 'mock-redis-test:zadd' }

  it "returns true if member wasn't present in the set" do
    @redises.zadd(@key, 1, 'foo').should == true
  end

  it 'returns false if member was present in the set' do
    @redises.zadd(@key, 1, 'foo')
    @redises.zadd(@key, 1, 'foo').should == false
  end

  it 'adds member to the set' do
    @redises.zadd(@key, 1, 'foo')
    @redises.zrange(@key, 0, -1).should == ['foo']
  end

  it 'treats integer members as strings' do
    member = 11
    @redises.zadd(@key, 1, member)
    @redises.zrange(@key, 0, -1).should == [member.to_s]
  end

  it 'allows scores to be set to Float::INFINITY' do
    member = '1'
    @redises.zadd(@key, Float::INFINITY, member)
    @redises.zrange(@key, 0, -1).should == [member]
  end

  it 'updates the score' do
    @redises.zadd(@key, 1, 'foo')
    @redises.zadd(@key, 2, 'foo')

    @redises.zscore(@key, 'foo').should == 2.0
  end

  it 'with XX option command do nothing if element not exist' do
    @redises.zadd(@key, 1, 'foo')
    @redises.zadd(@key, 2, 'bar', xx: true)
    @redises.zrange(@key, 0, -1).should_not include 'bar'
  end

  it 'with XX option command update index on exist element' do
    @redises.zadd(@key, 1, 'foo')
    @redises.zadd(@key, 2, 'foo', xx: true)
    @redises.zscore(@key, 'foo').should == 2.0
  end

  it 'with XX option and multiple elements command update index on exist element' do
    @redises.zadd(@key, 1, 'foo')
    added_count = @redises.zadd(@key, [[2, 'foo'], [2, 'bar']], xx: true)
    added_count.should == 0

    @redises.zscore(@key, 'foo').should == 2.0
    @redises.zrange(@key, 0, -1).should_not include 'bar'
  end

  it "with NX option don't update current element" do
    @redises.zadd(@key, 1, 'foo')
    @redises.zadd(@key, 2, 'foo', nx: true)
    @redises.zscore(@key, 'foo').should == 1.0
  end

  it 'with NX option create new element' do
    @redises.zadd(@key, 1, 'foo')
    @redises.zadd(@key, 2, 'bar', nx: true)
    @redises.zrange(@key, 0, -1).should include 'bar'
  end

  it 'with NX option and multiple elements command only create element' do
    @redises.zadd(@key, 1, 'foo')
    added_count = @redises.zadd(@key, [[2, 'foo'], [2, 'bar']], nx: true)
    added_count.should == 1
    @redises.zscore(@key, 'bar').should == 2.0
    @redises.zrange(@key, 0, -1).should eq %w[foo bar]
  end

  it 'XX and NX options in same time raise error' do
    lambda do
      @redises.zadd(@key, 1, 'foo', nx: true, xx: true)
    end.should raise_error(Redis::CommandError)
  end

  it 'with INCR is act like zincrby' do
    @redises.zadd(@key, 10, 'bert', incr: true).should == 10.0
    @redises.zadd(@key, 3, 'bert', incr: true).should == 13.0
  end

  it 'with INCR and XX not create element' do
    @redises.zadd(@key, 10, 'bert', xx: true, incr: true).should be_nil
  end

  it 'with INCR and XX increase score for exist element' do
    @redises.zadd(@key, 2, 'bert')
    @redises.zadd(@key, 10, 'bert', xx: true, incr: true).should == 12.0
  end

  it 'with INCR and NX create element with score' do
    @redises.zadd(@key, 11, 'bert', nx: true, incr: true).should == 11.0
  end

  it 'with INCR and NX not update element' do
    @redises.zadd(@key, 1, 'bert')
    @redises.zadd(@key, 10, 'bert', nx: true, incr: true).should be_nil
  end

  it 'with INCR with variable number of arguments raise error' do
    lambda do
      @redises.zadd(@key, [[1, 'one'], [2, 'two']], incr: true)
    end.should raise_error(Redis::CommandError)
  end

  it 'supports a variable number of arguments' do
    @redises.zadd(@key, [[1, 'one'], [2, 'two']])
    @redises.zadd(@key, [[3, 'three']])
    @redises.zrange(@key, 0, -1).should == %w[one two three]
  end

  it 'raises an error if an empty array is given' do
    lambda do
      @redises.zadd(@key, [])
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'arg 1 is a score'
  it_should_behave_like 'a zset-only command'
end
