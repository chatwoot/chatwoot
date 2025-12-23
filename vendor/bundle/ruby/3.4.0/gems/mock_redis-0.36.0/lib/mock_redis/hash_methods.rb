require 'mock_redis/assertions'
require 'mock_redis/utility_methods'

class MockRedis
  module HashMethods
    include Assertions
    include UtilityMethods

    def hdel(key, *fields)
      with_hash_at(key) do |hash|
        orig_size = hash.size
        fields = Array(fields).flatten.map(&:to_s)

        if fields.empty?
          raise Redis::CommandError, "ERR wrong number of arguments for 'hdel' command"
        end

        hash.delete_if { |k, _v| fields.include?(k) }
        orig_size - hash.size
      end
    end

    def hexists(key, field)
      with_hash_at(key) { |h| h.key?(field.to_s) }
    end

    def hget(key, field)
      with_hash_at(key) { |h| h[field.to_s] }
    end

    def hgetall(key)
      with_hash_at(key) { |h| h }
    end

    def hincrby(key, field, increment)
      with_hash_at(key) do |hash|
        field = field.to_s
        unless can_incr?(data[key][field])
          raise Redis::CommandError, 'ERR hash value is not an integer'
        end
        unless looks_like_integer?(increment.to_s)
          raise Redis::CommandError, 'ERR value is not an integer or out of range'
        end

        new_value = (hash[field] || '0').to_i + increment.to_i
        hash[field] = new_value.to_s
        new_value
      end
    end

    def hincrbyfloat(key, field, increment)
      with_hash_at(key) do |hash|
        field = field.to_s
        unless can_incr_float?(data[key][field])
          raise Redis::CommandError, 'ERR hash value is not a float'
        end

        unless looks_like_float?(increment.to_s)
          raise Redis::CommandError, 'ERR value is not a valid float'
        end

        new_value = (hash[field] || '0').to_f + increment.to_f
        new_value = new_value.to_i if new_value % 1 == 0
        hash[field] = new_value.to_s
        new_value
      end
    end

    def hkeys(key)
      with_hash_at(key, &:keys)
    end

    def hlen(key)
      hkeys(key).length
    end

    def hmget(key, *fields)
      fields.flatten!

      assert_has_args(fields, 'hmget')
      fields.map { |f| hget(key, f) }
    end

    def mapped_hmget(key, *fields)
      reply = hmget(key, *fields)
      if reply.is_a?(Array)
        Hash[fields.zip(reply)]
      else
        reply
      end
    end

    def hmset(key, *kvpairs)
      if key.is_a? Array
        err_msg = 'ERR wrong number of arguments for \'hmset\' command'
        kvpairs = key[1..-1]
        key = key[0]
      end

      kvpairs.flatten!
      assert_has_args(kvpairs, 'hmset')

      if kvpairs.length.odd?
        raise Redis::CommandError, err_msg || 'ERR wrong number of arguments for \'hmset\' command'
      end

      kvpairs.each_slice(2) do |(k, v)|
        hset(key, k, v)
      end
      'OK'
    end

    def mapped_hmset(key, hash)
      kvpairs = hash.to_a.flatten
      assert_has_args(kvpairs, 'hmset')
      if kvpairs.length.odd?
        raise Redis::CommandError, "ERR wrong number of arguments for 'hmset' command"
      end

      hmset(key, *kvpairs)
    end

    def hscan(key, cursor, opts = {})
      opts = opts.merge(key: lambda { |x| x[0] })
      common_scan(hgetall(key).to_a, cursor, opts)
    end

    def hscan_each(key, opts = {}, &block)
      return to_enum(:hscan_each, key, opts) unless block_given?
      cursor = 0
      loop do
        cursor, values = hscan(key, cursor, opts)
        values.each(&block)
        break if cursor == '0'
      end
    end

    def hset(key, *args)
      added = 0
      with_hash_at(key) do |hash|
        if args.length == 1 && args[0].is_a?(Hash)
          args = args[0].to_a.flatten
        end

        args.each_slice(2) do |field, value|
          added += 1 unless hash.key?(field.to_s)
          hash[field.to_s] = value.to_s
        end
      end
      added
    end

    def hsetnx(key, field, value)
      if hget(key, field)
        false
      else
        hset(key, field, value)
        true
      end
    end

    def hvals(key)
      with_hash_at(key, &:values)
    end

    private

    def with_hash_at(key, &blk)
      with_thing_at(key.to_s, :assert_hashy, proc { {} }, &blk)
    end

    def hashy?(key)
      data[key].nil? || data[key].is_a?(Hash)
    end

    def assert_hashy(key)
      unless hashy?(key)
        raise Redis::CommandError,
              'WRONGTYPE Operation against a key holding the wrong kind of value'
      end
    end
  end
end
