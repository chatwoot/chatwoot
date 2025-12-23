require 'spec_helper'

describe '#flushall [mock only]' do
  # don't want to hurt things in the real redis that are outside our
  # namespace.
  before { @mock = @redises.mock }
  before { @key = 'mock-redis-test:select' }

  it "returns 'OK'" do
    @mock.flushall.should == 'OK'
  end

  it 'removes all keys in the current DB' do
    @mock.set('k1', 'v1')
    @mock.lpush('k2', 'v2')

    @mock.flushall
    @mock.keys('*').should == []
  end

  it 'removes all keys in other DBs, too' do
    @mock.set('k1', 'v1')

    @mock.select(1)
    @mock.flushall
    @mock.select(0)

    @mock.get('k1').should be_nil
  end

  it 'removes expiration times' do
    @mock.set('k1', 'v1')
    @mock.expire('k1', 360_000)
    @mock.flushall
    @mock.set('k1', 'v1')
    @mock.ttl('k1').should == -1
  end
end
