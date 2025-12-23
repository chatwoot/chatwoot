# encoding: utf-8

require File.dirname(__FILE__) + '/spec_helper'
require 'connection_pool'

describe "redis" do
  @redis_version = Gem::Version.new(Redis.new.info["redis_version"])
  let(:redis_client) { @redis.respond_to?(:_client) ? @redis._client : @redis.client}

  before(:each) do
    # use database 15 for testing so we dont accidentally step on your real data
    @redis = Redis.new :db => 15
    @redis.flushdb
    @namespaced = Redis::Namespace.new(:ns, :redis => @redis)
    @redis.set('foo', 'bar')
  end

  # redis-rb 3.3.4+
  it "should inject :namespace into connection info" do
    info = @redis.connection.merge(:namespace => :ns)
    expect(@namespaced.connection).to eq(info)
  end

  it "proxies `client` to the _client and deprecated" do
    expect(@namespaced.client).to eq(redis_client)
  end

  it "proxies `_client` to the _client" do
    expect(@namespaced._client).to eq(redis_client)
  end

  it "should be able to use a namespace" do
    expect(@namespaced.get('foo')).to eq(nil)
    @namespaced.set('foo', 'chris')
    expect(@namespaced.get('foo')).to eq('chris')
    @redis.set('foo', 'bob')
    expect(@redis.get('foo')).to eq('bob')

    @namespaced.incrby('counter', 2)
    expect(@namespaced.get('counter').to_i).to eq(2)
    expect(@redis.get('counter')).to eq(nil)
    expect(@namespaced.type('counter')).to eq('string')
  end

  it "should work with Proc namespaces" do
    namespace = Proc.new { :dynamic_ns }
    namespaced = Redis::Namespace.new(namespace, redis: @redis)

    expect(namespaced.get('foo')).to eq(nil)
    namespaced.set('foo', 'chris')
    expect(namespaced.get('foo')).to eq('chris')
    @redis.set('foo', 'bob')
    expect(@redis.get('foo')).to eq('bob')
  end

  context 'when sending capital commands (issue 68)' do
    it 'should be able to use a namespace' do
      @namespaced.send('SET', 'fubar', 'quux')
      expect(@redis.get('fubar')).to be_nil
      expect(@namespaced.get('fubar')).to eq 'quux'
    end
  end

  it "should be able to use a namespace with bpop" do
    @namespaced.rpush "foo", "string"
    @namespaced.rpush "foo", "ns:string"
    @namespaced.rpush "foo", "string_no_timeout"
    expect(@namespaced.blpop("foo", 1)).to eq(["foo", "string"])
    expect(@namespaced.blpop("foo", 1)).to eq(["foo", "ns:string"])
    expect(@namespaced.blpop("foo")).to eq(["foo", "string_no_timeout"])
    expect(@namespaced.blpop("foo", 1)).to eq(nil)
  end

  it "should be able to use a namespace with del" do
    @namespaced.set('foo', 1000)
    @namespaced.set('bar', 2000)
    @namespaced.set('baz', 3000)
    @namespaced.del 'foo'
    expect(@namespaced.get('foo')).to eq(nil)
    @namespaced.del 'bar', 'baz'
    expect(@namespaced.get('bar')).to eq(nil)
    expect(@namespaced.get('baz')).to eq(nil)
  end

  it "should be able to use a namespace with unlink" do
    @namespaced.set('foo', 1000)
    @namespaced.set('bar', 2000)
    @namespaced.set('baz', 3000)
    @namespaced.unlink 'foo'
    expect(@namespaced.get('foo')).to eq(nil)
    @namespaced.unlink 'bar', 'baz'
    expect(@namespaced.get('bar')).to eq(nil)
    expect(@namespaced.get('baz')).to eq(nil)
  end

  it 'should be able to use a namespace with append' do
    @namespaced.set('foo', 'bar')
    expect(@namespaced.append('foo','n')).to eq(4)
    expect(@namespaced.get('foo')).to eq('barn')
    expect(@redis.get('foo')).to eq('bar')
  end

  it 'should be able to use a namespace with brpoplpush' do
    @namespaced.lpush('foo','bar')
    expect(@namespaced.brpoplpush('foo','bar',0)).to eq('bar')
    expect(@namespaced.lrange('foo',0,-1)).to eq([])
    expect(@namespaced.lrange('bar',0,-1)).to eq(['bar'])
  end

  it "should be able to use a namespace with getex" do
    expect(@namespaced.set('mykey', 'Hello')).to eq('OK')
    expect(@namespaced.getex('mykey', ex: 50)).to eq('Hello')
    expect(@namespaced.get('mykey')).to eq('Hello')
    expect(@namespaced.ttl('mykey')).to eq(50)
  end

  it 'should be able to use a namespace with getbit' do
    @namespaced.set('foo','bar')
    expect(@namespaced.getbit('foo',1)).to eq(1)
  end

  it 'should be able to use a namespace with getrange' do
    @namespaced.set('foo','bar')
    expect(@namespaced.getrange('foo',0,-1)).to eq('bar')
  end

  it 'should be able to use a namespace with linsert' do
    @namespaced.rpush('foo','bar')
    @namespaced.rpush('foo','barn')
    @namespaced.rpush('foo','bart')
    expect(@namespaced.linsert('foo','BEFORE','barn','barf')).to eq(4)
    expect(@namespaced.lrange('foo',0,-1)).to eq(['bar','barf','barn','bart'])
  end

  it 'should be able to use a namespace with lpushx' do
    expect(@namespaced.lpushx('foo','bar')).to eq(0)
    @namespaced.lpush('foo','boo')
    expect(@namespaced.lpushx('foo','bar')).to eq(2)
    expect(@namespaced.lrange('foo',0,-1)).to eq(['bar','boo'])
  end

  it 'should be able to use a namespace with rpushx' do
    expect(@namespaced.rpushx('foo','bar')).to eq(0)
    @namespaced.lpush('foo','boo')
    expect(@namespaced.rpushx('foo','bar')).to eq(2)
    expect(@namespaced.lrange('foo',0,-1)).to eq(['boo','bar'])
  end

  it 'should be able to use a namespace with setbit' do
    @namespaced.setbit('virgin_key', 1, 1)
    expect(@namespaced.exists?('virgin_key')).to be true
    expect(@namespaced.get('virgin_key')).to eq(@namespaced.getrange('virgin_key',0,-1))
  end

  it 'should be able to use a namespace with exists' do
    @namespaced.set('foo', 1000)
    @namespaced.set('bar', 2000)
    expect(@namespaced.exists('foo', 'bar')).to eq(2)
  end

  it 'should be able to use a namespace with exists?' do
    @namespaced.set('foo', 1000)
    @namespaced.set('bar', 2000)
    expect(@namespaced.exists?('does_not_exist', 'bar')).to eq(true)
  end

  it 'should be able to use a namespace with bitpos' do
    @namespaced.setbit('bit_map', 42, 1)
    expect(@namespaced.bitpos('bit_map', 0)).to eq(0)
    expect(@namespaced.bitpos('bit_map', 1)).to eq(42)
  end

  it 'should be able to use a namespace with setrange' do
    @namespaced.setrange('foo', 0, 'bar')
    expect(@namespaced.get('foo')).to eq('bar')

    @namespaced.setrange('bar', 2, 'foo')
    expect(@namespaced.get('bar')).to eq("\000\000foo")
  end

  it "should be able to use a namespace with mget" do
    @namespaced.set('foo', 1000)
    @namespaced.set('bar', 2000)
    expect(@namespaced.mapped_mget('foo', 'bar')).to eq({ 'foo' => '1000', 'bar' => '2000' })
    expect(@namespaced.mapped_mget('foo', 'baz', 'bar')).to eq({'foo'=>'1000', 'bar'=>'2000', 'baz' => nil})
  end

  it "should utilize connection_pool while using a namespace with mget" do
    memo = @namespaced
    connection_pool = ConnectionPool.new(size: 2, timeout: 2) { Redis.new db: 15 }
    @namespaced = Redis::Namespace.new(:ns, redis: connection_pool)

    expect(connection_pool).to receive(:with).and_call_original do |arg|
      expect(arg).to be(an_instance_of(Redis))
    end.at_least(:once)

    @namespaced.set('foo', 1000)
    @namespaced.set('bar', 2000)
    expect(@namespaced.mapped_mget('foo', 'bar')).to eq({ 'foo' => '1000', 'bar' => '2000' })
    expect(@namespaced.mapped_mget('foo', 'baz', 'bar')).to eq({'foo'=>'1000', 'bar'=>'2000', 'baz' => nil})
    @redis.get('foo').should eq('bar')

    @namespaced = memo
  end

  it "should be able to use a namespace with mset" do
    @namespaced.mset('foo', '1000', 'bar', '2000')
    expect(@namespaced.mapped_mget('foo', 'bar')).to eq({ 'foo' => '1000', 'bar' => '2000' })
    expect(@namespaced.mapped_mget('foo', 'baz', 'bar')).to eq({ 'foo' => '1000', 'bar' => '2000', 'baz' => nil})

    @namespaced.mapped_mset('foo' => '3000', 'bar' => '5000')
    expect(@namespaced.mapped_mget('foo', 'bar')).to eq({ 'foo' => '3000', 'bar' => '5000' })
    expect(@namespaced.mapped_mget('foo', 'baz', 'bar')).to eq({ 'foo' => '3000', 'bar' => '5000', 'baz' => nil})

    @namespaced.mset(['foo', '4000'], ['baz', '6000'])
    expect(@namespaced.mapped_mget('foo', 'bar', 'baz')).to eq({ 'foo' => '4000', 'bar' => '5000', 'baz' => '6000' })
  end

  it "should be able to use a namespace with msetnx" do
    @namespaced.msetnx('foo', '1000', 'bar', '2000')
    expect(@namespaced.mapped_mget('foo', 'bar')).to eq({ 'foo' => '1000', 'bar' => '2000' })
    expect(@namespaced.mapped_mget('foo', 'baz', 'bar')).to eq({ 'foo' => '1000', 'bar' => '2000', 'baz' => nil})

    @namespaced.msetnx(['baz', '4000'])
    expect(@namespaced.mapped_mget('foo', 'baz', 'bar')).to eq({ 'foo' => '1000', 'bar' => '2000', 'baz' => '4000'})
  end

  it "should be able to use a namespace with mapped_msetnx" do
    @namespaced.set('foo','1')
    expect(@namespaced.mapped_msetnx('foo'=>'1000', 'bar'=>'2000')).to be false
    expect(@namespaced.mapped_mget('foo', 'bar')).to eq({ 'foo' => '1', 'bar' => nil })
    expect(@namespaced.mapped_msetnx('bar'=>'2000', 'baz'=>'1000')).to be true
    expect(@namespaced.mapped_mget('foo', 'bar')).to eq({ 'foo' => '1', 'bar' => '2000' })
  end

  it "should be able to use a namespace with hashes" do
    @namespaced.hset('foo', 'key', 'value')
    @namespaced.hset('foo', 'key1', 'value1')
    expect(@namespaced.hget('foo', 'key')).to eq('value')
    expect(@namespaced.hgetall('foo')).to eq({'key' => 'value', 'key1' => 'value1'})
    expect(@namespaced.hlen('foo')).to eq(2)
    expect(@namespaced.hkeys('foo')).to eq(['key', 'key1'])
    @namespaced.hmset('bar', 'key', 'value', 'key1', 'value1')
    @namespaced.hmget('bar', 'key', 'key1')
    @namespaced.hmset('bar', 'a_number', 1)
    expect(@namespaced.hmget('bar', 'a_number')).to eq(['1'])
    @namespaced.hincrby('bar', 'a_number', 3)
    expect(@namespaced.hmget('bar', 'a_number')).to eq(['4'])
    expect(@namespaced.hgetall('bar')).to eq({'key' => 'value', 'key1' => 'value1', 'a_number' => '4'})

    expect(@namespaced.hsetnx('foonx','nx',10)).to be true
    expect(@namespaced.hsetnx('foonx','nx',12)).to be false
    expect(@namespaced.hget('foonx','nx')).to eq("10")
    expect(@namespaced.hkeys('foonx')).to eq(%w{ nx })
    expect(@namespaced.hvals('foonx')).to eq(%w{ 10 })
    @namespaced.mapped_hmset('baz', {'key' => 'value', 'key1' => 'value1', 'a_number' => 4})
    expect(@namespaced.mapped_hmget('baz', 'key', 'key1', 'a_number')).to eq({'key' => 'value', 'key1' => 'value1', 'a_number' => '4'})
    expect(@namespaced.hgetall('baz')).to eq({'key' => 'value', 'key1' => 'value1', 'a_number' => '4'})
  end

  it "should properly intersect three sets" do
    @namespaced.sadd('foo', 1)
    @namespaced.sadd('foo', 2)
    @namespaced.sadd('foo', 3)
    @namespaced.sadd('bar', 2)
    @namespaced.sadd('bar', 3)
    @namespaced.sadd('bar', 4)
    @namespaced.sadd('baz', 3)
    expect(@namespaced.sinter('foo', 'bar', 'baz')).to eq(%w( 3 ))
  end

  it "should properly union two sets" do
    @namespaced.sadd('foo', 1)
    @namespaced.sadd('foo', 2)
    @namespaced.sadd('bar', 2)
    @namespaced.sadd('bar', 3)
    @namespaced.sadd('bar', 4)
    expect(@namespaced.sunion('foo', 'bar').sort).to eq(%w( 1 2 3 4 ))
  end

  it "should properly union two sorted sets with options" do
    @namespaced.zadd('sort1', 1, 1)
    @namespaced.zadd('sort1', 2, 2)
    @namespaced.zadd('sort2', 2, 2)
    @namespaced.zadd('sort2', 3, 3)
    @namespaced.zadd('sort2', 4, 4)
    @namespaced.zunionstore('union', ['sort1', 'sort2'], weights: [2, 1])
    expect(@namespaced.zrevrange('union', 0, -1)).to eq(%w( 2 4 3 1 ))
  end

  it "should properly union two sorted sets without options" do
    @namespaced.zadd('sort1', 1, 1)
    @namespaced.zadd('sort1', 2, 2)
    @namespaced.zadd('sort2', 2, 2)
    @namespaced.zadd('sort2', 3, 3)
    @namespaced.zadd('sort2', 4, 4)
    @namespaced.zunionstore('union', ['sort1', 'sort2'])
    expect(@namespaced.zrevrange('union', 0, -1)).to eq(%w( 4 2 3 1 ))
  end

  it "should properly intersect two sorted sets without options" do
    @namespaced.zadd('food', 1, 'orange')
    @namespaced.zadd('food', 2, 'banana')
    @namespaced.zadd('food', 3, 'eggplant')

    @namespaced.zadd('color', 2, 'orange')
    @namespaced.zadd('color', 3, 'yellow')
    @namespaced.zadd('color', 4, 'eggplant')

    @namespaced.zinterstore('inter', ['food', 'color'])

    inter_values = @namespaced.zrevrange('inter', 0, -1, :with_scores => true)
    expect(inter_values).to match_array([['orange', 3.0], ['eggplant', 7.0]])
  end

  it "should properly intersect two sorted sets with options" do
    @namespaced.zadd('food', 1, 'orange')
    @namespaced.zadd('food', 2, 'banana')
    @namespaced.zadd('food', 3, 'eggplant')

    @namespaced.zadd('color', 2, 'orange')
    @namespaced.zadd('color', 3, 'yellow')
    @namespaced.zadd('color', 4, 'eggplant')

    @namespaced.zinterstore('inter', ['food', 'color'], :aggregate => "min")

    inter_values = @namespaced.zrevrange('inter', 0, -1, :with_scores => true)
    expect(inter_values).to match_array([['orange', 1.0], ['eggplant', 3.0]])
  end

  it "should return lexicographical range for sorted set" do
    @namespaced.zadd('food', 0, 'orange')
    @namespaced.zadd('food', 0, 'banana')
    @namespaced.zadd('food', 0, 'eggplant')

    values = @namespaced.zrangebylex('food', '[b', '(o')
    expect(values).to match_array(['banana', 'eggplant'])
  end

  it "should return the number of elements removed from the set" do
    @namespaced.zadd('food', 0, 'orange')
    @namespaced.zadd('food', 0, 'banana')
    @namespaced.zadd('food', 0, 'eggplant')

    removed = @namespaced.zremrangebylex('food', '[b', '(o')
    expect(removed).to eq(2)

    values = @namespaced.zrange('food', 0, -1)
    expect(values).to eq(['orange'])
  end

  it "should return reverce lexicographical range for sorted set" do
    @namespaced.zadd('food', 0, 'orange')
    @namespaced.zadd('food', 0, 'banana')
    @namespaced.zadd('food', 0, 'eggplant')

    values = @namespaced.zrevrangebylex('food', '(o', '[b')
    expect(values).to match_array(['banana', 'eggplant'])
  end

  it "should add a new member" do
    expect(@namespaced.sadd?('foo', 1)).to eq(true)
    expect(@namespaced.sadd?('foo', 1)).to eq(false)
  end

  it "should add namespace to sort" do
    @namespaced.sadd('foo', 1)
    @namespaced.sadd('foo', 2)
    @namespaced.set('weight_1', 2)
    @namespaced.set('weight_2', 1)
    @namespaced.set('value_1', 'a')
    @namespaced.set('value_2', 'b')

    expect(@namespaced.sort('foo')).to eq(%w( 1 2 ))
    expect(@namespaced.sort('foo', :limit => [0, 1])).to eq(%w( 1 ))
    expect(@namespaced.sort('foo', :order => 'desc')).to eq(%w( 2 1 ))
    expect(@namespaced.sort('foo', :by => 'weight_*')).to eq(%w( 2 1 ))
    expect(@namespaced.sort('foo', :get => 'value_*')).to eq(%w( a b ))
    expect(@namespaced.sort('foo', :get => '#')).to eq(%w( 1 2 ))
    expect(@namespaced.sort('foo', :get => ['#', 'value_*'])).to eq([["1", "a"], ["2", "b"]])

    @namespaced.sort('foo', :store => 'result')
    expect(@namespaced.lrange('result', 0, -1)).to eq(%w( 1 2 ))
  end

  it "should yield the correct list of keys" do
    @namespaced.set("foo", 1)
    @namespaced.set("bar", 2)
    @namespaced.set("baz", 3)
    expect(@namespaced.keys("*").sort).to eq(%w( bar baz foo ))
    expect(@namespaced.keys.sort).to eq(%w( bar baz foo ))
  end

  it "should add namepsace to multi blocks" do
    @namespaced.mapped_hmset "foo", {"key" => "value"}
    @namespaced.multi do |r|
      r.del "foo"
      r.mapped_hmset "foo", {"key1" => "value1"}
    end
    expect(@namespaced.hgetall("foo")).to eq({"key1" => "value1"})
  end

  it "should utilize connection_pool while adding namepsace to multi blocks" do
    memo = @namespaced
    connection_pool = ConnectionPool.new(size: 2, timeout: 2) { Redis.new db: 15 }
    @namespaced = Redis::Namespace.new(:ns, redis: connection_pool)

    expect(connection_pool).to receive(:with).and_call_original do |arg|
      expect(arg).to be(an_instance_of(Redis))
    end.at_least(:once)

    @namespaced.mapped_hmset "foo", {"key" => "value"}
    @namespaced.multi do |r|
      r.del "foo"
      r.mapped_hmset "foo", {"key1" => "value1"}
    end
    expect(@redis.get("foo")).to eq("bar")
    expect(@namespaced.hgetall("foo")).to eq({"key1" => "value1"})

    @namespaced = memo
  end

  it "should pass through multi commands without block" do
    @namespaced.mapped_hmset "foo", {"key" => "value"}

    @namespaced.multi
    @namespaced.del "foo"
    @namespaced.mapped_hmset "foo", {"key1" => "value1"}
    @namespaced.exec

    expect(@namespaced.hgetall("foo")).to eq({"key1" => "value1"})
  end

  it "should utilize connection_pool while passing through multi commands without block" do
    memo = @namespaced
    connection_pool = ConnectionPool.new(size: 2, timeout: 2) { Redis.new db: 15 }
    @namespaced = Redis::Namespace.new(:ns, redis: connection_pool)

    expect(connection_pool).to receive(:with).and_call_original do |arg|
      expect(arg).to be(an_instance_of(Redis))
    end.at_least(:once)

    @namespaced.mapped_hmset "foo", {"key" => "value"}

    @namespaced.multi
    @namespaced.del "foo"
    @namespaced.mapped_hmset "foo", {"key1" => "value1"}
    @namespaced.exec

    expect(@namespaced.hgetall("foo")).to eq({"key1" => "value1"})
    expect(@redis.get("foo")).to eq("bar")

    @namespaced = memo
  end

  it 'should return futures without attempting to remove namespaces' do
    @namespaced.multi do
      @future = @namespaced.keys('*')
    end
    expect(@future.class).to be(Redis::Future)
  end

  it "should add namespace to pipelined blocks" do
    @namespaced.mapped_hmset "foo", {"key" => "value"}
    @namespaced.pipelined do |r|
      r.del "foo"
      r.mapped_hmset "foo", {"key1" => "value1"}
    end
    expect(@namespaced.hgetall("foo")).to eq({"key1" => "value1"})
  end

  it "should utilize connection_pool while adding namespace to pipelined blocks" do
    memo = @namespaced
    connection_pool = ConnectionPool.new(size: 2, timeout: 2) { Redis.new db: 15 }
    @namespaced = Redis::Namespace.new(:ns, redis: connection_pool)

    expect(connection_pool).to receive(:with).and_call_original do |arg|
      expect(arg).to be(an_instance_of(Redis))
    end.at_least(:once)

    @namespaced.mapped_hmset "foo", {"key" => "value"}
    @namespaced.pipelined do |r|
      r.del "foo"
      r.mapped_hmset "foo", {"key1" => "value1"}
    end
    expect(@namespaced.hgetall("foo")).to eq({"key1" => "value1"})
    expect(@redis.get("foo")).to eq("bar")

    @namespaced = memo
  end

  it "should returned response array from pipelined block" do
    @namespaced.mset "foo", "bar", "key", "value"
    result = @namespaced.pipelined do |r|
      r.get("foo")
      r.get("key")
    end
    expect(result).to eq(["bar", "value"])
  end

  it "is thread safe for multi blocks" do
    mon = Monitor.new
    entered = false
    entered_cond = mon.new_cond

    thread = Thread.new do
      mon.synchronize do
        entered_cond.wait_until { entered }
        @namespaced.multi
      end
    end

    @namespaced.multi do |transaction|
      entered = true
      mon.synchronize { entered_cond.signal }
      thread.join(0.1)
      transaction.get("foo")
    end
    thread.join
  end

  it "should add namespace to strlen" do
    @namespaced.set("mykey", "123456")
    expect(@namespaced.strlen("mykey")).to eq(6)
  end

  it "should not add namespace to echo" do
    expect(@namespaced.echo(123)).to eq("123")
  end

  it 'should not add namespace to disconnect!' do
    expect(@redis).to receive(:disconnect!).with(no_args).and_call_original

    expect(@namespaced.disconnect!).to be nil
  end

  it "can change its namespace" do
    expect(@namespaced.get('foo')).to eq(nil)
    @namespaced.set('foo', 'chris')
    expect(@namespaced.get('foo')).to eq('chris')

    expect(@namespaced.namespace).to eq(:ns)
    @namespaced.namespace = :spec
    expect(@namespaced.namespace).to eq(:spec)

    expect(@namespaced.get('foo')).to eq(nil)
    @namespaced.set('foo', 'chris')
    expect(@namespaced.get('foo')).to eq('chris')
  end

  it "can accept a temporary namespace" do
    expect(@namespaced.namespace).to eq(:ns)
    expect(@namespaced.get('foo')).to eq(nil)

    @namespaced.namespace(:spec) do |temp_ns|
      expect(temp_ns.namespace).to eq(:spec)
      expect(temp_ns.get('foo')).to eq(nil)
      temp_ns.set('foo', 'jake')
      expect(temp_ns.get('foo')).to eq('jake')
    end

    expect(@namespaced.namespace).to eq(:ns)
    expect(@namespaced.get('foo')).to eq(nil)
  end

  it "should respond to :namespace=" do
    expect(@namespaced.respond_to?(:namespace=)).to eq(true)
  end

  it "should respond to :warning=" do
    expect(@namespaced.respond_to?(:warning=)).to eq(true)
  end

  it "should raise an exception when an unknown command is passed" do
    expect { @namespaced.unknown('foo') }.to raise_exception NoMethodError
  end

  describe '#inspect' do
    let(:single_level_names) { %i[first] }
    let(:double_level_names) { %i[first second] }
    let(:triple_level_names) { %i[first second third] }
    let(:namespace_builder) do
      ->(redis, *namespaces) { namespaces.reduce(redis) { |r, n| Redis::Namespace.new(n, redis: r) } }
    end
    let(:regexp_builder) do
      ->(*namespaces) { %r{/#{namespaces.join(':')}>\z} }
    end

    context 'when one namespace' do
      let(:single_namespaced) { namespace_builder.call(@redis, *single_level_names) }
      let(:regexp) { regexp_builder.call(*single_level_names) }

      it 'should have correct ending of inspect string' do
        expect(regexp =~ single_namespaced.inspect).not_to be(nil)
      end
    end

    context 'when two namespaces' do
      let(:double_namespaced) { namespace_builder.call(@redis, *double_level_names) }
      let(:regexp) { regexp_builder.call(*double_level_names) }

      it 'should have correct ending of inspect string' do
        expect(regexp =~ double_namespaced.inspect).not_to be(nil)
      end
    end

    context 'when three namespaces' do
      let(:triple_namespaced) { namespace_builder.call(@redis, *triple_level_names) }
      let(:regexp) { regexp_builder.call(*triple_level_names) }

      it 'should have correct ending of inspect string' do
        expect(regexp =~ triple_namespaced.inspect).not_to be(nil)
      end
    end
  end

  # Redis 2.6 RC reports its version as 2.5.
  if @redis_version >= Gem::Version.new("2.5.0")
    describe "redis 2.6 commands" do
      it "should namespace bitcount" do
        @redis.set('ns:foo', 'foobar')
        expect(@namespaced.bitcount('foo')).to eq 26
        expect(@namespaced.bitcount('foo', 0, 0)).to eq 4
        expect(@namespaced.bitcount('foo', 1, 1)).to eq 6
        expect(@namespaced.bitcount('foo', 3, 5)).to eq 10
      end

      it "should namespace bitop" do
        try_encoding('UTF-8') do
          @redis.set("ns:foo", "a")
          @redis.set("ns:bar", "b")

          @namespaced.bitop(:and, "foo&bar", "foo", "bar")
          @namespaced.bitop(:or, "foo|bar", "foo", "bar")
          @namespaced.bitop(:xor, "foo^bar", "foo", "bar")
          @namespaced.bitop(:not, "~foo", "foo")

          expect(@redis.get("ns:foo&bar")).to eq "\x60"
          expect(@redis.get("ns:foo|bar")).to eq "\x63"
          expect(@redis.get("ns:foo^bar")).to eq "\x03"
          expect(@redis.get("ns:~foo")).to eq "\x9E"
        end
      end

      it "should namespace dump and restore" do
        @redis.set("ns:foo", "a")
        v = @namespaced.dump("foo")
        @redis.del("ns:foo")

        expect(@namespaced.restore("foo", 1000, v)).to be_truthy
        expect(@redis.get("ns:foo")).to eq 'a'
        expect(@redis.ttl("ns:foo")).to satisfy {|v| (0..1).include?(v) }

        @redis.rpush("ns:bar", %w(b c d))
        w = @namespaced.dump("bar")
        @redis.del("ns:bar")

        expect(@namespaced.restore("bar", 1000, w)).to be_truthy
        expect(@redis.lrange('ns:bar', 0, -1)).to eq %w(b c d)
        expect(@redis.ttl("ns:foo")).to satisfy {|v| (0..1).include?(v) }
      end

      it "should namespace hincrbyfloat" do
        @namespaced.hset('mykey', 'field', 10.50)
        expect(@namespaced.hincrbyfloat('mykey', 'field', 0.1)).to eq(10.6)
      end

      it "should namespace incrbyfloat" do
        @namespaced.set('mykey', 10.50)
        expect(@namespaced.incrbyfloat('mykey', 0.1)).to eq(10.6)
      end

      it "should namespace object" do
        @namespaced.set('foo', 1000)
        expect(@namespaced.object('encoding', 'foo')).to eq('int')
      end

      it "should namespace persist" do
        @namespaced.set('mykey', 'Hello')
        @namespaced.expire('mykey', 60)
        expect(@namespaced.persist('mykey')).to eq(true)
        expect(@namespaced.ttl('mykey')).to eq(-1)
      end

      it "should namespace pexpire" do
        @namespaced.set('mykey', 'Hello')
        expect(@namespaced.pexpire('mykey', 60000)).to eq(true)
      end

      it "should namespace pexpireat" do
        @namespaced.set('mykey', 'Hello')
        expect(@namespaced.pexpire('mykey', 1555555555005)).to eq(true)
      end

      it "should namespace psetex" do
        expect(@namespaced.psetex('mykey', 10000, 'Hello')).to eq('OK')
        expect(@namespaced.get('mykey')).to eq('Hello')
      end

      it "should namespace pttl" do
        @namespaced.set('mykey', 'Hello')
        @namespaced.expire('mykey', 1)
        expect(@namespaced.pttl('mykey')).to be >= 0
      end

      it "should namespace eval keys passed in as array args" do
        expect(@namespaced.
          eval("return {KEYS[1], KEYS[2]}", %w[k1 k2], %w[arg1 arg2])).
          to eq(%w[ns:k1 ns:k2])
      end

      it "should namespace eval keys passed in as hash args" do
        expect(@namespaced.
          eval("return {KEYS[1], KEYS[2]}", :keys => %w[k1 k2], :argv => %w[arg1 arg2])).
          to eq(%w[ns:k1 ns:k2])
      end

      it "should namespace eval keys passed in as hash args unmodified" do
        args = { :keys => %w[k1 k2], :argv => %w[arg1 arg2] }
        args.freeze
        expect(@namespaced.
          eval("return {KEYS[1], KEYS[2]}", args)).
          to eq(%w[ns:k1 ns:k2])
      end

      context '#evalsha' do
        let!(:sha) do
          @redis.script(:load, "return {KEYS[1], KEYS[2]}")
        end

        it "should namespace evalsha keys passed in as array args" do
          expect(@namespaced.
            evalsha(sha, %w[k1 k2], %w[arg1 arg2])).
            to eq(%w[ns:k1 ns:k2])
        end

        it "should namespace evalsha keys passed in as hash args" do
          expect(@namespaced.
            evalsha(sha, :keys => %w[k1 k2], :argv => %w[arg1 arg2])).
            to eq(%w[ns:k1 ns:k2])
        end

        it "should namespace evalsha keys passed in as hash args unmodified" do
          args = { :keys => %w[k1 k2], :argv => %w[arg1 arg2] }
          args.freeze
          expect(@namespaced.
            evalsha(sha, args)).
            to eq(%w[ns:k1 ns:k2])
        end
      end

      context "in a nested namespace" do
        let(:nested_namespace) { Redis::Namespace.new(:nest, :redis => @namespaced) }
        let(:sha) { @redis.script(:load, "return {KEYS[1], KEYS[2]}") }

        it "should namespace eval keys passed in as hash args" do
          expect(nested_namespace.
          eval("return {KEYS[1], KEYS[2]}", :keys => %w[k1 k2], :argv => %w[arg1 arg2])).
          to eq(%w[ns:nest:k1 ns:nest:k2])
        end
        it "should namespace evalsha keys passed in as hash args" do
          expect(nested_namespace.evalsha(sha, :keys => %w[k1 k2], :argv => %w[arg1 arg2])).
            to eq(%w[ns:nest:k1 ns:nest:k2])
        end
      end
    end
  end

  # Redis 2.8 RC reports its version as 2.7.
  if @redis_version >= Gem::Version.new("2.7.105")
    describe "redis 2.8 commands" do
      context 'keyspace scan methods' do
        let(:keys) do
          %w(alpha ns:beta gamma ns:delta ns:epsilon ns:zeta:one ns:zeta:two ns:theta)
        end
        let(:namespaced_keys) do
          keys.map{|k| k.dup.sub!(/\Ans:/,'') }.compact.sort
        end
        before(:each) do
          keys.each do |key|
            @redis.set(key, key)
          end
        end
        let(:matching_namespaced_keys) do
          namespaced_keys.select{|k| k[/\Azeta:/] }.compact.sort
        end

        context '#scan' do
          context 'when :match supplied' do
            it 'should retrieve the proper keys' do
              _, result = @namespaced.scan(0, :match => 'zeta:*', :count => 1000)
              expect(result).to match_array(matching_namespaced_keys)
            end
          end
          context 'without :match supplied' do
            it 'should retrieve the proper keys' do
              _, result = @namespaced.scan(0, :count => 1000)
              expect(result).to match_array(namespaced_keys)
            end
          end
        end if Redis.new.respond_to?(:scan)

        context '#scan_each' do
          context 'when :match supplied' do
            context 'when given a block' do
              it 'should yield unnamespaced' do
                results = []
                @namespaced.scan_each(:match => 'zeta:*', :count => 1000) {|k| results << k }
                expect(results).to match_array(matching_namespaced_keys)
              end
            end
            context 'without a block' do
              it 'should return an Enumerator that un-namespaces' do
                enum = @namespaced.scan_each(:match => 'zeta:*', :count => 1000)
                expect(enum.to_a).to match_array(matching_namespaced_keys)
              end
            end
          end
          context 'without :match supplied' do
            context 'when given a block' do
              it 'should yield unnamespaced' do
                results = []
                @namespaced.scan_each(:count => 1000){ |k| results << k }
                expect(results).to match_array(namespaced_keys)
              end
            end
            context 'without a block' do
              it 'should return an Enumerator that un-namespaces' do
                enum = @namespaced.scan_each(:count => 1000)
                expect(enum.to_a).to match_array(namespaced_keys)
              end
            end
          end
        end if Redis.new.respond_to?(:scan_each)
      end

      context 'hash scan methods' do
        before(:each) do
          @redis.mapped_hmset('hsh', {'zeta:wrong:one' => 'WRONG', 'wrong:two' => 'WRONG'})
          @redis.mapped_hmset('ns:hsh', hash)
        end
        let(:hash) do
          {'zeta:one' => 'OK', 'zeta:two' => 'OK', 'three' => 'OKAY'}
        end
        let(:hash_matching_subset) do
          # select is not consistent from 1.8.7 -> 1.9.2 :(
          hash.reject {|k,v| !k[/\Azeta:/] }
        end
        context '#hscan' do
          context 'when supplied :match' do
            it 'should retrieve the proper keys' do
              _, results = @namespaced.hscan('hsh', 0, :match => 'zeta:*')
              expect(results).to match_array(hash_matching_subset.to_a)
            end
          end
          context 'without :match supplied' do
            it 'should retrieve all hash keys' do
              _, results = @namespaced.hscan('hsh', 0)
              expect(results).to match_array(@redis.hgetall('ns:hsh').to_a)
            end
          end
        end if Redis.new.respond_to?(:hscan)

        context '#hscan_each' do
          context 'when :match supplied' do
            context 'when given a block' do
              it 'should yield the correct hash keys unchanged' do
                results = []
                @namespaced.hscan_each('hsh', :match => 'zeta:*', :count => 1000) { |kv| results << kv}
                expect(results).to match_array(hash_matching_subset.to_a)
              end
            end
            context 'without a block' do
              it 'should return an Enumerator that yields the correct hash keys unchanged' do
                enum = @namespaced.hscan_each('hsh', :match => 'zeta:*', :count => 1000)
                expect(enum.to_a).to match_array(hash_matching_subset.to_a)
              end
            end
          end
          context 'without :match supplied' do
            context 'when given a block' do
              it 'should yield all hash keys unchanged' do
                results = []
                @namespaced.hscan_each('hsh', :count => 1000){ |k| results << k }
                expect(results).to match_array(hash.to_a)
              end
            end
            context 'without a block' do
              it 'should return an Enumerator that yields all keys unchanged' do
                enum = @namespaced.hscan_each('hsh', :count => 1000)
                expect(enum.to_a).to match_array(hash.to_a)
              end
            end
          end
        end if Redis.new.respond_to?(:hscan_each)
      end

      context 'set scan methods' do
        before(:each) do
          set.each { |elem| @namespaced.sadd('set', elem) }
          @redis.sadd('set', 'WRONG')
        end
        let(:set) do
          %w(zeta:one zeta:two three)
        end
        let(:matching_subset) do
          set.select { |e| e[/\Azeta:/] }
        end

        context '#sscan' do
          context 'when supplied :match' do
            it 'should retrieve the matching set members from the proper set' do
              _, results = @namespaced.sscan('set', 0, :match => 'zeta:*', :count => 1000)
              expect(results).to match_array(matching_subset)
            end
          end
          context 'without :match supplied' do
            it 'should retrieve all set members from the proper set' do
              _, results = @namespaced.sscan('set', 0, :count => 1000)
              expect(results).to match_array(set)
            end
          end
        end if Redis.new.respond_to?(:sscan)

        context '#sscan_each' do
          context 'when :match supplied' do
            context 'when given a block' do
              it 'should yield the correct hset elements unchanged' do
                results = []
                @namespaced.sscan_each('set', :match => 'zeta:*', :count => 1000) { |kv| results << kv}
                expect(results).to match_array(matching_subset)
              end
            end
            context 'without a block' do
              it 'should return an Enumerator that yields the correct set elements unchanged' do
                enum = @namespaced.sscan_each('set', :match => 'zeta:*', :count => 1000)
                expect(enum.to_a).to match_array(matching_subset)
              end
            end
          end
          context 'without :match supplied' do
            context 'when given a block' do
              it 'should yield all set elements unchanged' do
                results = []
                @namespaced.sscan_each('set', :count => 1000){ |k| results << k }
                expect(results).to match_array(set)
              end
            end
            context 'without a block' do
              it 'should return an Enumerator that yields all set elements unchanged' do
                enum = @namespaced.sscan_each('set', :count => 1000)
                expect(enum.to_a).to match_array(set)
              end
            end
          end
        end if Redis.new.respond_to?(:sscan_each)
      end

      context 'zset scan methods' do
        before(:each) do
          hash.each {|member, score| @namespaced.zadd('zset', score, member)}
          @redis.zadd('zset', 123.45, 'WRONG')
        end
        let(:hash) do
          {'zeta:one' => 1, 'zeta:two' => 2, 'three' => 3}
        end
        let(:hash_matching_subset) do
          # select is not consistent from 1.8.7 -> 1.9.2 :(
          hash.reject {|k,v| !k[/\Azeta:/] }
        end
        context '#zscan' do
          context 'when supplied :match' do
            it 'should retrieve the matching set elements and their scores' do
              results = []
              @namespaced.zscan_each('zset', :match => 'zeta:*', :count => 1000) { |ms| results << ms }
              expect(results).to match_array(hash_matching_subset.to_a)
            end
          end
          context 'without :match supplied' do
            it 'should retrieve all set elements and their scores' do
              results = []
              @namespaced.zscan_each('zset', :count => 1000) { |ms| results << ms }
              expect(results).to match_array(hash.to_a)
            end
          end
        end if Redis.new.respond_to?(:zscan)

        context '#zscan_each' do
          context 'when :match supplied' do
            context 'when given a block' do
              it 'should yield the correct set elements and scores unchanged' do
                results = []
                @namespaced.zscan_each('zset', :match => 'zeta:*', :count => 1000) { |ms| results << ms}
                expect(results).to match_array(hash_matching_subset.to_a)
              end
            end
            context 'without a block' do
              it 'should return an Enumerator that yields the correct set elements and scoresunchanged' do
                enum = @namespaced.zscan_each('zset', :match => 'zeta:*', :count => 1000)
                expect(enum.to_a).to match_array(hash_matching_subset.to_a)
              end
            end
          end
          context 'without :match supplied' do
            context 'when given a block' do
              it 'should yield all set elements and scores unchanged' do
                results = []
                @namespaced.zscan_each('zset', :count => 1000){ |ms| results << ms }
                expect(results).to match_array(hash.to_a)
              end
            end
            context 'without a block' do
              it 'should return an Enumerator that yields all set elements and scores unchanged' do
                enum = @namespaced.zscan_each('zset', :count => 1000)
                expect(enum.to_a).to match_array(hash.to_a)
              end
            end
          end
        end if Redis.new.respond_to?(:zscan_each)
      end
    end
  end

  if @redis_version >= Gem::Version.new("2.8.9")
    it 'should namespace pfadd' do
      5.times { |n| @namespaced.pfadd("pf", n) }
      expect(@redis.pfcount("ns:pf")).to eq(5)
    end

    it 'should namespace pfcount' do
      5.times { |n| @redis.pfadd("ns:pf", n) }
      expect(@namespaced.pfcount("pf")).to eq(5)
    end

    it 'should namespace pfmerge' do
      5.times do |n|
        @redis.pfadd("ns:pfa", n)
        @redis.pfadd("ns:pfb", n+5)
      end

      @namespaced.pfmerge("pfc", "pfa", "pfb")
      expect(@redis.pfcount("ns:pfc")).to eq(10)
    end
  end

  describe :full_namespace do
    it "should return the full namespace including sub namespaces" do
      sub_namespaced     = Redis::Namespace.new(:sub1, :redis => @namespaced)
      sub_sub_namespaced = Redis::Namespace.new(:sub2, :redis => sub_namespaced)

      expect(@namespaced.full_namespace).to eql("ns")
      expect(sub_namespaced.full_namespace).to eql("ns:sub1")
      expect(sub_sub_namespaced.full_namespace).to eql("ns:sub1:sub2")
    end
  end

  describe :clear do
    it "warns with helpful output" do
      expect { @namespaced.clear }.to output(/can run for a very long time/).to_stderr
    end

    it "should delete all the keys" do
      @redis.set("foo", "bar")
      @namespaced.mset("foo1", "bar", "foo2", "bar")
      capture_stderr { @namespaced.clear }

      expect(@redis.keys).to eq ["foo"]
      expect(@namespaced.keys).to be_empty
    end

    it "should delete all the keys in older redis" do
      allow(@redis).to receive(:info).and_return({ "redis_version" => "2.7.0" })

      @redis.set("foo", "bar")
      @namespaced.mset("foo1", "bar", "foo2", "bar")
      capture_stderr { @namespaced.clear }

      expect(@redis.keys).to eq ["foo"]
      expect(@namespaced.keys).to be_empty
    end
  end
end
