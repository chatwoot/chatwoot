require 'spec_helper'

describe '#sadd(key, member)' do
  before { @key = 'mock-redis-test:sadd' }

  it 'returns true if the set did not already contain member' do
    @redises.sadd(@key, 1).should == true
  end

  it 'returns false if the set did already contain member' do
    @redises.sadd(@key, 1)
    @redises.sadd(@key, 1).should == false
  end

  it 'adds member to the set' do
    @redises.sadd(@key, 1)
    @redises.sadd(@key, 2)
    @redises.smembers(@key).should == %w[2 1]
  end

  describe 'adding multiple members at once' do
    it 'returns the amount of added members' do
      @redises.sadd(@key, [1, 2, 3]).should == 3
      @redises.sadd(@key, [1, 2, 3, 4]).should == 1
    end

    it 'returns 0 if the set did already contain all members' do
      @redises.sadd(@key, [1, 2, 3])
      @redises.sadd(@key, [1, 2, 3]).should == 0
    end

    it 'adds the members to the set' do
      @redises.sadd(@key, [1, 2, 3])
      @redises.smembers(@key).should == %w[1 2 3]
    end

    it 'raises an error if an empty array is given' do
      lambda do
        @redises.sadd(@key, [])
      end.should raise_error(Redis::CommandError)
    end
  end

  it_should_behave_like 'a set-only command'
end
