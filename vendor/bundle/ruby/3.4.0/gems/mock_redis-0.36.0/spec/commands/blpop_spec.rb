require 'spec_helper'

describe '#blpop(key [, key, ...,], timeout)' do
  before do
    @list1 = 'mock-redis-test:blpop1'
    @list2 = 'mock-redis-test:blpop2'

    @redises.rpush(@list1, 'one')
    @redises.rpush(@list1, 'two')
    @redises.rpush(@list2, 'ten')
    @redises.rpush(@list2, 'eleven')
  end

  it 'returns [first-nonempty-list, popped-value]' do
    @redises.blpop(@list1, @list2).should == [@list1, 'one']
  end

  it 'pops that value off the list' do
    @redises.blpop(@list1, @list2)
    @redises.blpop(@list1, @list2)

    @redises.blpop(@list1, @list2).should == [@list2, 'ten']
  end

  it 'ignores empty keys' do
    @redises.blpop('mock-redis-test:not-here', @list1).should ==
      [@list1, 'one']
  end

  it 'raises an error on negative timeout' do
    lambda do
      @redises.blpop(@list1, @list2, :timeout => -1)
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a list-only command'

  context '[mock only]' do
    it 'ignores positive timeouts and returns nil' do
      @redises.mock.blpop('mock-redis-test:not-here', :timeout => 1).should be_nil
    end

    it 'ignores positive legacy timeouts and returns nil' do
      @redises.mock.blpop('mock-redis-test:not-here', 1).should be_nil
    end

    it 'raises WouldBlock on zero timeout (no blocking in the mock)' do
      lambda do
        @redises.mock.blpop('mock-redis-test:not-here', :timeout => 0)
      end.should raise_error(MockRedis::WouldBlock)
    end
  end
end
