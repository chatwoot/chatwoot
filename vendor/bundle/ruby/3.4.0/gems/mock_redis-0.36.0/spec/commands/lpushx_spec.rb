require 'spec_helper'

describe '#lpushx(key, value)' do
  before { @key = 'mock-redis-test:81267' }

  it 'returns the new size of the list' do
    @redises.lpush(@key, 'X')

    @redises.lpushx(@key, 'X').should == 2
    @redises.lpushx(@key, 'X').should == 3
  end

  it 'does nothing when run against a nonexistent key' do
    @redises.lpushx(@key, 'value')
    @redises.get(@key).should be_nil
  end

  it 'prepends items to the list' do
    @redises.lpush(@key, 'bert')
    @redises.lpushx(@key, 'ernie')

    @redises.lindex(@key, 0).should == 'ernie'
    @redises.lindex(@key, 1).should == 'bert'
  end

  it 'stores values as strings' do
    @redises.lpush(@key, 1)
    @redises.lpushx(@key, 2)
    @redises.lindex(@key, 0).should == '2'
  end

  it 'raises an error if an empty array is given' do
    @redises.lpush(@key, 'X')
    lambda do
      @redises.lpushx(@key, [])
    end.should raise_error(Redis::CommandError)
  end

  it 'stores multiple items if an array of more than one item is given' do
    @redises.lpush(@key, 'X')
    @redises.lpushx(@key, [1, 2]).should == 3
    @redises.lrange(@key, 0, -1).should == %w[2 1 X]
  end

  it_should_behave_like 'a list-only command'
end
