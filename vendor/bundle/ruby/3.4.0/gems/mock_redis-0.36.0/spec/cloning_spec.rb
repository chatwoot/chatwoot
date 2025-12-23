require 'spec_helper'

describe 'MockRedis#clone' do
  before do
    @mock = MockRedis.new
  end

  context 'the stored data' do
    before do
      @mock.set('foo', 'bar')
      @mock.hset('foohash', 'bar', 'baz')
      @mock.lpush('foolist', 'bar')
      @mock.sadd('fooset', 'bar')
      @mock.zadd('foozset', 1, 'bar')

      @clone = @mock.clone
    end

    it 'copies the stored data to the clone' do
      @clone.get('foo').should == 'bar'
    end

    it 'performs a deep copy (string values)' do
      @mock.del('foo')
      @clone.get('foo').should == 'bar'
    end

    it 'performs a deep copy (list values)' do
      @mock.lpop('foolist')
      @clone.lrange('foolist', 0, 1).should == ['bar']
    end

    it 'performs a deep copy (hash values)' do
      @mock.hset('foohash', 'bar', 'quux')
      @clone.hgetall('foohash').should == { 'bar' => 'baz' }
    end

    it 'performs a deep copy (set values)' do
      @mock.srem('fooset', 'bar')
      @clone.smembers('fooset').should == ['bar']
    end

    it 'performs a deep copy (zset values)' do
      @mock.zadd('foozset', 2, 'bar')
      @clone.zscore('foozset', 'bar').should == 1.0
    end
  end

  context 'expiration times' do
    before do
      @mock.set('foo', 1)
      @mock.expire('foo', 60_026)

      @clone = @mock.clone
    end

    it 'copies the expiration times' do
      @clone.ttl('foo').should > 0
    end

    it 'deep-copies the expiration times' do
      @mock.persist('foo')
      @clone.ttl('foo').should > 0
    end

    it 'deep-copies the expiration times' do
      @clone.persist('foo')
      @mock.ttl('foo').should > 0
    end
  end

  context 'transactional info' do
    before do
      @mock.multi
      @mock.incr('foo')
      @mock.incrby('foo', 2)
      @mock.incrby('foo', 4)

      @clone = @mock.clone
    end

    it 'makes sure the clone is in a transaction' do
      lambda do
        @clone.exec
      end.should_not raise_error
    end

    it 'deep-copies the queued commands' do
      @clone.incrby('foo', 8)
      @clone.exec.should == [1, 3, 7, 15]

      @mock.exec.should == [1, 3, 7]
    end
  end
end
