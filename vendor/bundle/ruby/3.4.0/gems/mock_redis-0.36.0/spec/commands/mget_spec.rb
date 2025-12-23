require 'spec_helper'

describe '#mget(key [, key, ...])' do
  before do
    @key1 = 'mock-redis-test:mget1'
    @key2 = 'mock-redis-test:mget2'

    @redises.set(@key1, 1)
    @redises.set(@key2, 2)
  end

  context 'emulate param array' do
    it 'returns an array of values' do
      @redises.mget([@key1, @key2]).should == %w[1 2]
    end

    it 'returns an array of values' do
      @redises.mget([@key1, @key2]).should == %w[1 2]
    end

    it 'returns nil for non-string keys' do
      list = 'mock-redis-test:mget-list'

      @redises.lpush(list, 'bork bork bork')

      @redises.mget([@key1, @key2, list]).should == ['1', '2', nil]
    end
  end

  context 'emulate params strings' do
    it 'returns an array of values' do
      @redises.mget(@key1, @key2).should == %w[1 2]
    end

    it 'returns nil for missing keys' do
      @redises.mget(@key1, 'mock-redis-test:not-found', @key2).should == ['1', nil, '2']
    end

    it 'returns nil for non-string keys' do
      list = 'mock-redis-test:mget-list'

      @redises.lpush(list, 'bork bork bork')

      @redises.mget(@key1, @key2, list).should == ['1', '2', nil]
    end

    it 'raises an error if you pass it 0 arguments' do
      lambda do
        @redises.mget
      end.should raise_error(Redis::CommandError)
    end

    it 'raises an error if you pass it empty array' do
      lambda do
        @redises.mget([])
      end.should raise_error(Redis::CommandError)
    end
  end

  context 'emulate block' do
    it 'returns an array of values' do
      @redises.mget(@key1, @key2) { |values| values.map(&:to_i) }.should == [1, 2]
    end
  end
end
