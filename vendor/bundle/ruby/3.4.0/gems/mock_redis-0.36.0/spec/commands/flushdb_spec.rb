require 'spec_helper'

describe '#flushdb [mock only]' do
  # don't want to hurt things in the real redis that are outside our
  # namespace.
  before { @mock = @redises.mock }
  before { @key = 'mock-redis-test:select' }

  it "returns 'OK'" do
    @mock.flushdb.should == 'OK'
  end

  it 'removes all keys in the current DB' do
    @mock.set('k1', 'v1')
    @mock.lpush('k2', 'v2')

    @mock.flushdb
    @mock.keys('*').should == []
  end

  it 'leaves other databases alone' do
    @mock.set('k1', 'v1')

    @mock.select(1)
    @mock.flushdb
    @mock.select(0)

    @mock.get('k1').should == 'v1'
  end

  it 'removes expiration times' do
    @mock.set('k1', 'v1')
    @mock.expire('k1', 360_000)
    @mock.flushdb
    @mock.set('k1', 'v1')
    @mock.ttl('k1').should == -1
  end
end
