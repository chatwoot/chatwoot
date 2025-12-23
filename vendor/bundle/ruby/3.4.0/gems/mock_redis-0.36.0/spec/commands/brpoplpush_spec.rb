require 'spec_helper'

require 'spec_helper'

describe '#brpoplpush(source, destination, timeout)' do
  before do
    @list1 = 'mock-redis-test:brpoplpush1'
    @list2 = 'mock-redis-test:brpoplpush2'

    @redises.rpush(@list1, 'A')
    @redises.rpush(@list1, 'B')

    @redises.rpush(@list2, 'alpha')
    @redises.rpush(@list2, 'beta')
  end

  it 'takes the last element of source and prepends it to destination' do
    @redises.brpoplpush(@list1, @list2)
    @redises.lrange(@list1, 0, -1).should == %w[A]
    @redises.lrange(@list2, 0, -1).should == %w[B alpha beta]
  end

  it 'returns the moved element' do
    @redises.brpoplpush(@list1, @list2).should == 'B'
  end

  it 'raises an error on negative timeout' do
    lambda do
      @redises.brpoplpush(@list1, @list2, :timeout => -1)
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a list-only command'

  context '[mock only]' do
    it 'ignores positive timeouts and returns nil' do
      @redises.mock.brpoplpush('mock-redis-test:not-here', @list1, :timeout => 1).
        should be_nil
    end

    it 'ignores positive legacy timeouts and returns nil' do
      @redises.mock.brpoplpush('mock-redis-test:not-here', @list1, 1).
        should be_nil
    end

    it 'raises WouldBlock on zero timeout (no blocking in the mock)' do
      lambda do
        @redises.mock.brpoplpush('mock-redis-test:not-here', @list1, :timeout => 0)
      end.should raise_error(MockRedis::WouldBlock)
    end
  end
end
