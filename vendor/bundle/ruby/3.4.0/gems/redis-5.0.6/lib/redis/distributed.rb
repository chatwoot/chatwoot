# frozen_string_literal: true

require "redis/hash_ring"

class Redis
  class Distributed
    class CannotDistribute < RuntimeError
      def initialize(command)
        @command = command
      end

      def message
        "#{@command.to_s.upcase} cannot be used in Redis::Distributed because the keys involved need " \
          "to be on the same server or because we cannot guarantee that the operation will be atomic."
      end
    end

    attr_reader :ring

    def initialize(node_configs, options = {})
      @tag = options[:tag] || /^\{(.+?)\}/
      @ring = options[:ring] || HashRing.new
      @node_configs = node_configs.map(&:dup)
      @default_options = options.dup
      node_configs.each { |node_config| add_node(node_config) }
      @subscribed_node = nil
      @watch_key = nil
    end

    def node_for(key)
      key = key_tag(key.to_s) || key.to_s
      raise CannotDistribute, :watch if @watch_key && @watch_key != key

      @ring.get_node(key)
    end

    def nodes
      @ring.nodes
    end

    def add_node(options)
      options = { url: options } if options.is_a?(String)
      options = @default_options.merge(options)
      options.delete(:tag)
      options.delete(:ring)
      @ring.add_node Redis.new(options)
    end

    # Change the selected database for the current connection.
    def select(db)
      on_each_node :select, db
    end

    # Ping the server.
    def ping
      on_each_node :ping
    end

    # Echo the given string.
    def echo(value)
      on_each_node :echo, value
    end

    # Close the connection.
    def quit
      on_each_node :quit
    end

    def close
      on_each_node :close
    end

    # Asynchronously save the dataset to disk.
    def bgsave
      on_each_node :bgsave
    end

    # Return the number of keys in the selected database.
    def dbsize
      on_each_node :dbsize
    end

    # Remove all keys from all databases.
    def flushall
      on_each_node :flushall
    end

    # Remove all keys from the current database.
    def flushdb
      on_each_node :flushdb
    end

    # Get information and statistics about the server.
    def info(cmd = nil)
      on_each_node :info, cmd
    end

    # Get the UNIX time stamp of the last successful save to disk.
    def lastsave
      on_each_node :lastsave
    end

    # Listen for all requests received by the server in real time.
    def monitor
      raise NotImplementedError
    end

    # Synchronously save the dataset to disk.
    def save
      on_each_node :save
    end

    # Get server time: an UNIX timestamp and the elapsed microseconds in the current second.
    def time
      on_each_node :time
    end

    # Remove the expiration from a key.
    def persist(key)
      node_for(key).persist(key)
    end

    # Set a key's time to live in seconds.
    def expire(key, seconds, **kwargs)
      node_for(key).expire(key, seconds, **kwargs)
    end

    # Set the expiration for a key as a UNIX timestamp.
    def expireat(key, unix_time, **kwargs)
      node_for(key).expireat(key, unix_time, **kwargs)
    end

    # Get the time to live (in seconds) for a key.
    def ttl(key)
      node_for(key).ttl(key)
    end

    # Set a key's time to live in milliseconds.
    def pexpire(key, milliseconds, **kwarg)
      node_for(key).pexpire(key, milliseconds, **kwarg)
    end

    # Set the expiration for a key as number of milliseconds from UNIX Epoch.
    def pexpireat(key, ms_unix_time, **kwarg)
      node_for(key).pexpireat(key, ms_unix_time, **kwarg)
    end

    # Get the time to live (in milliseconds) for a key.
    def pttl(key)
      node_for(key).pttl(key)
    end

    # Return a serialized version of the value stored at a key.
    def dump(key)
      node_for(key).dump(key)
    end

    # Create a key using the serialized value, previously obtained using DUMP.
    def restore(key, ttl, serialized_value, **options)
      node_for(key).restore(key, ttl, serialized_value, **options)
    end

    # Transfer a key from the connected instance to another instance.
    def migrate(_key, _options)
      raise CannotDistribute, :migrate
    end

    # Delete a key.
    def del(*args)
      args.flatten!(1)
      keys_per_node = args.group_by { |key| node_for(key) }
      keys_per_node.inject(0) do |sum, (node, keys)|
        sum + node.del(*keys)
      end
    end

    # Unlink keys.
    def unlink(*args)
      args.flatten!(1)
      keys_per_node = args.group_by { |key| node_for(key) }
      keys_per_node.inject(0) do |sum, (node, keys)|
        sum + node.unlink(*keys)
      end
    end

    # Determine if a key exists.
    def exists(*args)
      args.flatten!(1)
      keys_per_node = args.group_by { |key| node_for(key) }
      keys_per_node.inject(0) do |sum, (node, keys)|
        sum + node.exists(*keys)
      end
    end

    # Determine if any of the keys exists.
    def exists?(*args)
      args.flatten!(1)
      keys_per_node = args.group_by { |key| node_for(key) }
      keys_per_node.each do |node, keys|
        return true if node.exists?(*keys)
      end
      false
    end

    # Find all keys matching the given pattern.
    def keys(glob = "*")
      on_each_node(:keys, glob).flatten
    end

    # Move a key to another database.
    def move(key, db)
      node_for(key).move(key, db)
    end

    # Copy a value from one key to another.
    def copy(source, destination, **options)
      ensure_same_node(:copy, [source, destination]) do |node|
        node.copy(source, destination, **options)
      end
    end

    # Return a random key from the keyspace.
    def randomkey
      raise CannotDistribute, :randomkey
    end

    # Rename a key.
    def rename(old_name, new_name)
      ensure_same_node(:rename, [old_name, new_name]) do |node|
        node.rename(old_name, new_name)
      end
    end

    # Rename a key, only if the new key does not exist.
    def renamenx(old_name, new_name)
      ensure_same_node(:renamenx, [old_name, new_name]) do |node|
        node.renamenx(old_name, new_name)
      end
    end

    # Sort the elements in a list, set or sorted set.
    def sort(key, **options)
      keys = [key, options[:by], options[:store], *Array(options[:get])].compact

      ensure_same_node(:sort, keys) do |node|
        node.sort(key, **options)
      end
    end

    # Determine the type stored at key.
    def type(key)
      node_for(key).type(key)
    end

    # Decrement the integer value of a key by one.
    def decr(key)
      node_for(key).decr(key)
    end

    # Decrement the integer value of a key by the given number.
    def decrby(key, decrement)
      node_for(key).decrby(key, decrement)
    end

    # Increment the integer value of a key by one.
    def incr(key)
      node_for(key).incr(key)
    end

    # Increment the integer value of a key by the given integer number.
    def incrby(key, increment)
      node_for(key).incrby(key, increment)
    end

    # Increment the numeric value of a key by the given float number.
    def incrbyfloat(key, increment)
      node_for(key).incrbyfloat(key, increment)
    end

    # Set the string value of a key.
    def set(key, value, **options)
      node_for(key).set(key, value, **options)
    end

    # Set the time to live in seconds of a key.
    def setex(key, ttl, value)
      node_for(key).setex(key, ttl, value)
    end

    # Set the time to live in milliseconds of a key.
    def psetex(key, ttl, value)
      node_for(key).psetex(key, ttl, value)
    end

    # Set the value of a key, only if the key does not exist.
    def setnx(key, value)
      node_for(key).setnx(key, value)
    end

    # Set multiple keys to multiple values.
    def mset(*)
      raise CannotDistribute, :mset
    end

    def mapped_mset(_hash)
      raise CannotDistribute, :mapped_mset
    end

    # Set multiple keys to multiple values, only if none of the keys exist.
    def msetnx(*)
      raise CannotDistribute, :msetnx
    end

    def mapped_msetnx(_hash)
      raise CannotDistribute, :mapped_msetnx
    end

    # Get the value of a key.
    def get(key)
      node_for(key).get(key)
    end

    # Get the value of a key and delete it.
    def getdel(key)
      node_for(key).getdel(key)
    end

    # Get the value of a key and sets its time to live based on options.
    def getex(key, **options)
      node_for(key).getex(key, **options)
    end

    # Get the values of all the given keys as an Array.
    def mget(*keys)
      keys.flatten!(1)
      mapped_mget(*keys).values_at(*keys)
    end

    # Get the values of all the given keys as a Hash.
    def mapped_mget(*keys)
      keys.flatten!(1)
      keys.group_by { |k| node_for k }.inject({}) do |results, (node, subkeys)|
        results.merge! node.mapped_mget(*subkeys)
      end
    end

    # Overwrite part of a string at key starting at the specified offset.
    def setrange(key, offset, value)
      node_for(key).setrange(key, offset, value)
    end

    # Get a substring of the string stored at a key.
    def getrange(key, start, stop)
      node_for(key).getrange(key, start, stop)
    end

    # Sets or clears the bit at offset in the string value stored at key.
    def setbit(key, offset, value)
      node_for(key).setbit(key, offset, value)
    end

    # Returns the bit value at offset in the string value stored at key.
    def getbit(key, offset)
      node_for(key).getbit(key, offset)
    end

    # Append a value to a key.
    def append(key, value)
      node_for(key).append(key, value)
    end

    # Count the number of set bits in a range of the string value stored at key.
    def bitcount(key, start = 0, stop = -1)
      node_for(key).bitcount(key, start, stop)
    end

    # Perform a bitwise operation between strings and store the resulting string in a key.
    def bitop(operation, destkey, *keys)
      keys.flatten!(1)
      ensure_same_node(:bitop, [destkey] + keys) do |node|
        node.bitop(operation, destkey, keys)
      end
    end

    # Return the position of the first bit set to 1 or 0 in a string.
    def bitpos(key, bit, start = nil, stop = nil)
      node_for(key).bitpos(key, bit, start, stop)
    end

    # Set the string value of a key and return its old value.
    def getset(key, value)
      node_for(key).getset(key, value)
    end

    # Get the length of the value stored in a key.
    def strlen(key)
      node_for(key).strlen(key)
    end

    def [](key)
      get(key)
    end

    def []=(key, value)
      set(key, value)
    end

    # Get the length of a list.
    def llen(key)
      node_for(key).llen(key)
    end

    # Remove the first/last element in a list, append/prepend it to another list and return it.
    def lmove(source, destination, where_source, where_destination)
      ensure_same_node(:lmove, [source, destination]) do |node|
        node.lmove(source, destination, where_source, where_destination)
      end
    end

    # Remove the first/last element in a list and append/prepend it
    # to another list and return it, or block until one is available.
    def blmove(source, destination, where_source, where_destination, timeout: 0)
      ensure_same_node(:lmove, [source, destination]) do |node|
        node.blmove(source, destination, where_source, where_destination, timeout: timeout)
      end
    end

    # Prepend one or more values to a list.
    def lpush(key, value)
      node_for(key).lpush(key, value)
    end

    # Prepend a value to a list, only if the list exists.
    def lpushx(key, value)
      node_for(key).lpushx(key, value)
    end

    # Append one or more values to a list.
    def rpush(key, value)
      node_for(key).rpush(key, value)
    end

    # Append a value to a list, only if the list exists.
    def rpushx(key, value)
      node_for(key).rpushx(key, value)
    end

    # Remove and get the first elements in a list.
    def lpop(key, count = nil)
      node_for(key).lpop(key, count)
    end

    # Remove and get the last elements in a list.
    def rpop(key, count = nil)
      node_for(key).rpop(key, count)
    end

    # Remove the last element in a list, append it to another list and return
    # it.
    def rpoplpush(source, destination)
      ensure_same_node(:rpoplpush, [source, destination]) do |node|
        node.rpoplpush(source, destination)
      end
    end

    def _bpop(cmd, args)
      timeout = if args.last.is_a?(Hash)
        options = args.pop
        options[:timeout]
      end

      args.flatten!(1)

      ensure_same_node(cmd, args) do |node|
        if timeout
          node.__send__(cmd, args, timeout: timeout)
        else
          node.__send__(cmd, args)
        end
      end
    end

    # Remove and get the first element in a list, or block until one is
    # available.
    def blpop(*args)
      _bpop(:blpop, args)
    end

    def bzpopmax(*args)
      _bpop(:bzpopmax, args) do |reply|
        reply.is_a?(Array) ? [reply[0], reply[1], Floatify.call(reply[2])] : reply
      end
    end

    def bzpopmin(*args)
      _bpop(:bzpopmin, args) do |reply|
        reply.is_a?(Array) ? [reply[0], reply[1], Floatify.call(reply[2])] : reply
      end
    end

    # Remove and get the last element in a list, or block until one is
    # available.
    def brpop(*args)
      _bpop(:brpop, args)
    end

    # Pop a value from a list, push it to another list and return it; or block
    # until one is available.
    def brpoplpush(source, destination, **options)
      ensure_same_node(:brpoplpush, [source, destination]) do |node|
        node.brpoplpush(source, destination, **options)
      end
    end

    # Get an element from a list by its index.
    def lindex(key, index)
      node_for(key).lindex(key, index)
    end

    # Insert an element before or after another element in a list.
    def linsert(key, where, pivot, value)
      node_for(key).linsert(key, where, pivot, value)
    end

    # Get a range of elements from a list.
    def lrange(key, start, stop)
      node_for(key).lrange(key, start, stop)
    end

    # Remove elements from a list.
    def lrem(key, count, value)
      node_for(key).lrem(key, count, value)
    end

    # Set the value of an element in a list by its index.
    def lset(key, index, value)
      node_for(key).lset(key, index, value)
    end

    # Trim a list to the specified range.
    def ltrim(key, start, stop)
      node_for(key).ltrim(key, start, stop)
    end

    # Get the number of members in a set.
    def scard(key)
      node_for(key).scard(key)
    end

    # Add one or more members to a set.
    def sadd(key, *members)
      node_for(key).sadd(key, *members)
    end

    # Add one or more members to a set.
    def sadd?(key, *members)
      node_for(key).sadd?(key, *members)
    end

    # Remove one or more members from a set.
    def srem(key, *members)
      node_for(key).srem(key, *members)
    end

    # Remove one or more members from a set.
    def srem?(key, *members)
      node_for(key).srem?(key, *members)
    end

    # Remove and return a random member from a set.
    def spop(key, count = nil)
      node_for(key).spop(key, count)
    end

    # Get a random member from a set.
    def srandmember(key, count = nil)
      node_for(key).srandmember(key, count)
    end

    # Move a member from one set to another.
    def smove(source, destination, member)
      ensure_same_node(:smove, [source, destination]) do |node|
        node.smove(source, destination, member)
      end
    end

    # Determine if a given value is a member of a set.
    def sismember(key, member)
      node_for(key).sismember(key, member)
    end

    # Determine if multiple values are members of a set.
    def smismember(key, *members)
      node_for(key).smismember(key, *members)
    end

    # Get all the members in a set.
    def smembers(key)
      node_for(key).smembers(key)
    end

    # Scan a set
    def sscan(key, cursor, **options)
      node_for(key).sscan(key, cursor, **options)
    end

    # Scan a set and return an enumerator
    def sscan_each(key, **options, &block)
      node_for(key).sscan_each(key, **options, &block)
    end

    # Subtract multiple sets.
    def sdiff(*keys)
      keys.flatten!(1)
      ensure_same_node(:sdiff, keys) do |node|
        node.sdiff(keys)
      end
    end

    # Subtract multiple sets and store the resulting set in a key.
    def sdiffstore(destination, *keys)
      keys.flatten!(1)
      ensure_same_node(:sdiffstore, [destination].concat(keys)) do |node|
        node.sdiffstore(destination, keys)
      end
    end

    # Intersect multiple sets.
    def sinter(*keys)
      keys.flatten!(1)
      ensure_same_node(:sinter, keys) do |node|
        node.sinter(keys)
      end
    end

    # Intersect multiple sets and store the resulting set in a key.
    def sinterstore(destination, *keys)
      keys.flatten!(1)
      ensure_same_node(:sinterstore, [destination].concat(keys)) do |node|
        node.sinterstore(destination, keys)
      end
    end

    # Add multiple sets.
    def sunion(*keys)
      keys.flatten!(1)
      ensure_same_node(:sunion, keys) do |node|
        node.sunion(keys)
      end
    end

    # Add multiple sets and store the resulting set in a key.
    def sunionstore(destination, *keys)
      keys.flatten!(1)
      ensure_same_node(:sunionstore, [destination].concat(keys)) do |node|
        node.sunionstore(destination, keys)
      end
    end

    # Get the number of members in a sorted set.
    def zcard(key)
      node_for(key).zcard(key)
    end

    # Add one or more members to a sorted set, or update the score for members
    # that already exist.
    def zadd(key, *args)
      node_for(key).zadd(key, *args)
    end
    ruby2_keywords(:zadd) if respond_to?(:ruby2_keywords, true)

    # Increment the score of a member in a sorted set.
    def zincrby(key, increment, member)
      node_for(key).zincrby(key, increment, member)
    end

    # Remove one or more members from a sorted set.
    def zrem(key, member)
      node_for(key).zrem(key, member)
    end

    # Get the score associated with the given member in a sorted set.
    def zscore(key, member)
      node_for(key).zscore(key, member)
    end

    # Get one or more random members from a sorted set.
    def zrandmember(key, count = nil, **options)
      node_for(key).zrandmember(key, count, **options)
    end

    # Get the scores associated with the given members in a sorted set.
    def zmscore(key, *members)
      node_for(key).zmscore(key, *members)
    end

    # Return a range of members in a sorted set, by index, score or lexicographical ordering.
    def zrange(key, start, stop, **options)
      node_for(key).zrange(key, start, stop, **options)
    end

    # Select a range of members in a sorted set, by index, score or lexicographical ordering
    # and store the resulting sorted set in a new key.
    def zrangestore(dest_key, src_key, start, stop, **options)
      ensure_same_node(:zrangestore, [dest_key, src_key]) do |node|
        node.zrangestore(dest_key, src_key, start, stop, **options)
      end
    end

    # Return a range of members in a sorted set, by index, with scores ordered
    # from high to low.
    def zrevrange(key, start, stop, **options)
      node_for(key).zrevrange(key, start, stop, **options)
    end

    # Determine the index of a member in a sorted set.
    def zrank(key, member)
      node_for(key).zrank(key, member)
    end

    # Determine the index of a member in a sorted set, with scores ordered from
    # high to low.
    def zrevrank(key, member)
      node_for(key).zrevrank(key, member)
    end

    # Remove all members in a sorted set within the given indexes.
    def zremrangebyrank(key, start, stop)
      node_for(key).zremrangebyrank(key, start, stop)
    end

    # Return a range of members in a sorted set, by score.
    def zrangebyscore(key, min, max, **options)
      node_for(key).zrangebyscore(key, min, max, **options)
    end

    # Return a range of members in a sorted set, by score, with scores ordered
    # from high to low.
    def zrevrangebyscore(key, max, min, **options)
      node_for(key).zrevrangebyscore(key, max, min, **options)
    end

    # Remove all members in a sorted set within the given scores.
    def zremrangebyscore(key, min, max)
      node_for(key).zremrangebyscore(key, min, max)
    end

    # Get the number of members in a particular score range.
    def zcount(key, min, max)
      node_for(key).zcount(key, min, max)
    end

    # Get the intersection of multiple sorted sets
    def zinter(*keys, **options)
      keys.flatten!(1)
      ensure_same_node(:zinter, keys) do |node|
        node.zinter(keys, **options)
      end
    end

    # Intersect multiple sorted sets and store the resulting sorted set in a new
    # key.
    def zinterstore(destination, *keys, **options)
      keys.flatten!(1)
      ensure_same_node(:zinterstore, [destination].concat(keys)) do |node|
        node.zinterstore(destination, keys, **options)
      end
    end

    # Return the union of multiple sorted sets.
    def zunion(*keys, **options)
      keys.flatten!(1)
      ensure_same_node(:zunion, keys) do |node|
        node.zunion(keys, **options)
      end
    end

    # Add multiple sorted sets and store the resulting sorted set in a new key.
    def zunionstore(destination, *keys, **options)
      keys.flatten!(1)
      ensure_same_node(:zunionstore, [destination].concat(keys)) do |node|
        node.zunionstore(destination, keys, **options)
      end
    end

    # Return the difference between the first and all successive input sorted sets.
    def zdiff(*keys, **options)
      keys.flatten!(1)
      ensure_same_node(:zdiff, keys) do |node|
        node.zdiff(keys, **options)
      end
    end

    # Compute the difference between the first and all successive input sorted sets
    # and store the resulting sorted set in a new key.
    def zdiffstore(destination, *keys, **options)
      keys.flatten!(1)
      ensure_same_node(:zdiffstore, [destination] + keys) do |node|
        node.zdiffstore(destination, keys, **options)
      end
    end

    # Get the number of fields in a hash.
    def hlen(key)
      node_for(key).hlen(key)
    end

    # Set multiple hash fields to multiple values.
    def hset(key, *attrs)
      node_for(key).hset(key, *attrs)
    end

    # Set the value of a hash field, only if the field does not exist.
    def hsetnx(key, field, value)
      node_for(key).hsetnx(key, field, value)
    end

    # Set multiple hash fields to multiple values.
    def hmset(key, *attrs)
      node_for(key).hmset(key, *attrs)
    end

    def mapped_hmset(key, hash)
      node_for(key).hmset(key, hash)
    end

    # Get the value of a hash field.
    def hget(key, field)
      node_for(key).hget(key, field)
    end

    # Get the values of all the given hash fields.
    def hmget(key, *fields)
      fields.flatten!(1)
      node_for(key).hmget(key, fields)
    end

    def mapped_hmget(key, *fields)
      fields.flatten!(1)
      node_for(key).mapped_hmget(key, fields)
    end

    def hrandfield(key, count = nil, **options)
      node_for(key).hrandfield(key, count, **options)
    end

    # Delete one or more hash fields.
    def hdel(key, *fields)
      fields.flatten!(1)
      node_for(key).hdel(key, fields)
    end

    # Determine if a hash field exists.
    def hexists(key, field)
      node_for(key).hexists(key, field)
    end

    # Increment the integer value of a hash field by the given integer number.
    def hincrby(key, field, increment)
      node_for(key).hincrby(key, field, increment)
    end

    # Increment the numeric value of a hash field by the given float number.
    def hincrbyfloat(key, field, increment)
      node_for(key).hincrbyfloat(key, field, increment)
    end

    # Get all the fields in a hash.
    def hkeys(key)
      node_for(key).hkeys(key)
    end

    # Get all the values in a hash.
    def hvals(key)
      node_for(key).hvals(key)
    end

    # Get all the fields and values in a hash.
    def hgetall(key)
      node_for(key).hgetall(key)
    end

    # Post a message to a channel.
    def publish(channel, message)
      node_for(channel).publish(channel, message)
    end

    def subscribed?
      !!@subscribed_node
    end

    # Listen for messages published to the given channels.
    def subscribe(channel, *channels, &block)
      if channels.empty?
        @subscribed_node = node_for(channel)
        @subscribed_node.subscribe(channel, &block)
      else
        ensure_same_node(:subscribe, [channel] + channels) do |node|
          @subscribed_node = node
          node.subscribe(channel, *channels, &block)
        end
      end
    end

    # Stop listening for messages posted to the given channels.
    def unsubscribe(*channels)
      raise SubscriptionError, "Can't unsubscribe if not subscribed." unless subscribed?

      @subscribed_node.unsubscribe(*channels)
    end

    # Listen for messages published to channels matching the given patterns.
    def psubscribe(*channels, &block)
      raise NotImplementedError
    end

    # Stop listening for messages posted to channels matching the given
    # patterns.
    def punsubscribe(*channels)
      raise NotImplementedError
    end

    # Watch the given keys to determine execution of the MULTI/EXEC block.
    def watch(*keys, &block)
      ensure_same_node(:watch, keys) do |node|
        @watch_key = key_tag(keys.first) || keys.first.to_s

        begin
          node.watch(*keys, &block)
        rescue StandardError
          @watch_key = nil
          raise
        end
      end
    end

    # Forget about all watched keys.
    def unwatch
      raise CannotDistribute, :unwatch unless @watch_key

      result = node_for(@watch_key).unwatch
      @watch_key = nil
      result
    end

    def pipelined
      raise CannotDistribute, :pipelined
    end

    # Mark the start of a transaction block.
    def multi(&block)
      raise CannotDistribute, :multi unless @watch_key

      node_for(@watch_key).multi(&block)
    end

    # Execute all commands issued after MULTI.
    def exec
      raise CannotDistribute, :exec unless @watch_key

      result = node_for(@watch_key).exec
      @watch_key = nil
      result
    end

    # Discard all commands issued after MULTI.
    def discard
      raise CannotDistribute, :discard unless @watch_key

      result = node_for(@watch_key).discard
      @watch_key = nil
      result
    end

    # Control remote script registry.
    def script(subcommand, *args)
      on_each_node(:script, subcommand, *args)
    end

    # Add one or more members to a HyperLogLog structure.
    def pfadd(key, member)
      node_for(key).pfadd(key, member)
    end

    # Get the approximate cardinality of members added to HyperLogLog structure.
    def pfcount(*keys)
      ensure_same_node(:pfcount, keys.flatten(1)) do |node|
        node.pfcount(keys)
      end
    end

    # Merge multiple HyperLogLog values into an unique value that will approximate the cardinality of the union of
    # the observed Sets of the source HyperLogLog structures.
    def pfmerge(dest_key, *source_key)
      ensure_same_node(:pfmerge, [dest_key, *source_key]) do |node|
        node.pfmerge(dest_key, *source_key)
      end
    end

    def _eval(cmd, args)
      script = args.shift
      options = args.pop if args.last.is_a?(Hash)
      options ||= {}

      keys = args.shift || options[:keys] || []
      argv = args.shift || options[:argv] || []

      ensure_same_node(cmd, keys) do |node|
        node.send(cmd, script, keys, argv)
      end
    end

    # Evaluate Lua script.
    def eval(*args)
      _eval(:eval, args)
    end

    # Evaluate Lua script by its SHA.
    def evalsha(*args)
      _eval(:evalsha, args)
    end

    def inspect
      "#<Redis client v#{Redis::VERSION} for #{nodes.map(&:id).join(', ')}>"
    end

    def dup
      self.class.new(@node_configs, @default_options)
    end

    protected

    def on_each_node(command, *args)
      nodes.map do |node|
        node.send(command, *args)
      end
    end

    def node_index_for(key)
      nodes.index(node_for(key))
    end

    def key_tag(key)
      key = key.to_s
      key[@tag, 1] if key.match?(@tag)
    end

    def ensure_same_node(command, keys)
      all = true

      tags = keys.map do |key|
        tag = key_tag(key)
        all = false unless tag
        tag
      end

      if (all && tags.uniq.size != 1) || (!all && keys.uniq.size != 1)
        # Not 1 unique tag or not 1 unique key
        raise CannotDistribute, command
      end

      yield(node_for(keys.first))
    end
  end
end
