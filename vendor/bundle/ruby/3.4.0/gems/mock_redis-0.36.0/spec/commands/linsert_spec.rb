require 'spec_helper'

describe '#linsert(key, :before|:after, pivot, value)' do
  before { @key = 'mock-redis-test:48733' }

  it 'returns the new size of the list when the pivot is found' do
    @redises.lpush(@key, 'X')

    @redises.linsert(@key, :before, 'X', 'Y').should == 2
    @redises.lpushx(@key, 'X').should == 3
  end

  it 'does nothing when run against a nonexistent key' do
    @redises.linsert(@key, :before, 1, 2).should == 0
    @redises.get(@key).should be_nil
  end

  it 'returns -1 if the pivot is not found' do
    @redises.lpush(@key, 1)
    @redises.linsert(@key, :after, 'X', 'Y').should == -1
  end

  it 'inserts elements before the pivot when given :before as position' do
    @redises.lpush(@key, 'bert')
    @redises.linsert(@key, :before, 'bert', 'ernie')

    @redises.lindex(@key, 0).should == 'ernie'
    @redises.lindex(@key, 1).should == 'bert'
  end

  it "inserts elements before the pivot when given 'before' as position" do
    @redises.lpush(@key, 'bert')
    @redises.linsert(@key, 'before', 'bert', 'ernie')

    @redises.lindex(@key, 0).should == 'ernie'
    @redises.lindex(@key, 1).should == 'bert'
  end

  it 'inserts elements after the pivot when given :after as position' do
    @redises.lpush(@key, 'bert')
    @redises.linsert(@key, :after, 'bert', 'ernie')

    @redises.lindex(@key, 0).should == 'bert'
    @redises.lindex(@key, 1).should == 'ernie'
  end

  it "inserts elements after the pivot when given 'after' as position" do
    @redises.lpush(@key, 'bert')
    @redises.linsert(@key, 'after', 'bert', 'ernie')

    @redises.lindex(@key, 0).should == 'bert'
    @redises.lindex(@key, 1).should == 'ernie'
  end

  it 'raises an error when given a position that is neither before nor after' do
    lambda do
      @redises.linsert(@key, :near, 1, 2)
    end.should raise_error(Redis::CommandError)
  end

  it 'stores values as strings' do
    @redises.lpush(@key, 1)
    @redises.linsert(@key, :before, 1, 2)
    @redises.lindex(@key, 0).should == '2'
  end

  it_should_behave_like 'a list-only command'
end
