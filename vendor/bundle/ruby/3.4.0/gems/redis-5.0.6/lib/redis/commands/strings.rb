# frozen_string_literal: true

class Redis
  module Commands
    module Strings
      # Decrement the integer value of a key by one.
      #
      # @example
      #   redis.decr("value")
      #     # => 4
      #
      # @param [String] key
      # @return [Integer] value after decrementing it
      def decr(key)
        send_command([:decr, key])
      end

      # Decrement the integer value of a key by the given number.
      #
      # @example
      #   redis.decrby("value", 5)
      #     # => 0
      #
      # @param [String] key
      # @param [Integer] decrement
      # @return [Integer] value after decrementing it
      def decrby(key, decrement)
        send_command([:decrby, key, Integer(decrement)])
      end

      # Increment the integer value of a key by one.
      #
      # @example
      #   redis.incr("value")
      #     # => 6
      #
      # @param [String] key
      # @return [Integer] value after incrementing it
      def incr(key)
        send_command([:incr, key])
      end

      # Increment the integer value of a key by the given integer number.
      #
      # @example
      #   redis.incrby("value", 5)
      #     # => 10
      #
      # @param [String] key
      # @param [Integer] increment
      # @return [Integer] value after incrementing it
      def incrby(key, increment)
        send_command([:incrby, key, Integer(increment)])
      end

      # Increment the numeric value of a key by the given float number.
      #
      # @example
      #   redis.incrbyfloat("value", 1.23)
      #     # => 1.23
      #
      # @param [String] key
      # @param [Float] increment
      # @return [Float] value after incrementing it
      def incrbyfloat(key, increment)
        send_command([:incrbyfloat, key, Float(increment)], &Floatify)
      end

      # Set the string value of a key.
      #
      # @param [String] key
      # @param [String] value
      # @param [Hash] options
      #   - `:ex => Integer`: Set the specified expire time, in seconds.
      #   - `:px => Integer`: Set the specified expire time, in milliseconds.
      #   - `:exat => Integer` : Set the specified Unix time at which the key will expire, in seconds.
      #   - `:pxat => Integer` : Set the specified Unix time at which the key will expire, in milliseconds.
      #   - `:nx => true`: Only set the key if it does not already exist.
      #   - `:xx => true`: Only set the key if it already exist.
      #   - `:keepttl => true`: Retain the time to live associated with the key.
      #   - `:get => true`: Return the old string stored at key, or nil if key did not exist.
      # @return [String, Boolean] `"OK"` or true, false if `:nx => true` or `:xx => true`
      def set(key, value, ex: nil, px: nil, exat: nil, pxat: nil, nx: nil, xx: nil, keepttl: nil, get: nil)
        args = [:set, key, value.to_s]
        args << "EX" << Integer(ex) if ex
        args << "PX" << Integer(px) if px
        args << "EXAT" << Integer(exat) if exat
        args << "PXAT" << Integer(pxat) if pxat
        args << "NX" if nx
        args << "XX" if xx
        args << "KEEPTTL" if keepttl
        args << "GET" if get

        if nx || xx
          send_command(args, &BoolifySet)
        else
          send_command(args)
        end
      end

      # Set the time to live in seconds of a key.
      #
      # @param [String] key
      # @param [Integer] ttl
      # @param [String] value
      # @return [String] `"OK"`
      def setex(key, ttl, value)
        send_command([:setex, key, Integer(ttl), value.to_s])
      end

      # Set the time to live in milliseconds of a key.
      #
      # @param [String] key
      # @param [Integer] ttl
      # @param [String] value
      # @return [String] `"OK"`
      def psetex(key, ttl, value)
        send_command([:psetex, key, Integer(ttl), value.to_s])
      end

      # Set the value of a key, only if the key does not exist.
      #
      # @param [String] key
      # @param [String] value
      # @return [Boolean] whether the key was set or not
      def setnx(key, value)
        send_command([:setnx, key, value.to_s], &Boolify)
      end

      # Set one or more values.
      #
      # @example
      #   redis.mset("key1", "v1", "key2", "v2")
      #     # => "OK"
      #
      # @param [Array<String>] args array of keys and values
      # @return [String] `"OK"`
      #
      # @see #mapped_mset
      def mset(*args)
        send_command([:mset] + args)
      end

      # Set one or more values.
      #
      # @example
      #   redis.mapped_mset({ "f1" => "v1", "f2" => "v2" })
      #     # => "OK"
      #
      # @param [Hash] hash keys mapping to values
      # @return [String] `"OK"`
      #
      # @see #mset
      def mapped_mset(hash)
        mset(hash.flatten)
      end

      # Set one or more values, only if none of the keys exist.
      #
      # @example
      #   redis.msetnx("key1", "v1", "key2", "v2")
      #     # => true
      #
      # @param [Array<String>] args array of keys and values
      # @return [Boolean] whether or not all values were set
      #
      # @see #mapped_msetnx
      def msetnx(*args)
        send_command([:msetnx, *args], &Boolify)
      end

      # Set one or more values, only if none of the keys exist.
      #
      # @example
      #   redis.mapped_msetnx({ "key1" => "v1", "key2" => "v2" })
      #     # => true
      #
      # @param [Hash] hash keys mapping to values
      # @return [Boolean] whether or not all values were set
      #
      # @see #msetnx
      def mapped_msetnx(hash)
        msetnx(hash.flatten)
      end

      # Get the value of a key.
      #
      # @param [String] key
      # @return [String]
      def get(key)
        send_command([:get, key])
      end

      # Get the values of all the given keys.
      #
      # @example
      #   redis.mget("key1", "key2")
      #     # => ["v1", "v2"]
      #
      # @param [Array<String>] keys
      # @return [Array<String>] an array of values for the specified keys
      #
      # @see #mapped_mget
      def mget(*keys, &blk)
        keys.flatten!(1)
        send_command([:mget, *keys], &blk)
      end

      # Get the values of all the given keys.
      #
      # @example
      #   redis.mapped_mget("key1", "key2")
      #     # => { "key1" => "v1", "key2" => "v2" }
      #
      # @param [Array<String>] keys array of keys
      # @return [Hash] a hash mapping the specified keys to their values
      #
      # @see #mget
      def mapped_mget(*keys)
        mget(*keys) do |reply|
          if reply.is_a?(Array)
            Hash[keys.zip(reply)]
          else
            reply
          end
        end
      end

      # Overwrite part of a string at key starting at the specified offset.
      #
      # @param [String] key
      # @param [Integer] offset byte offset
      # @param [String] value
      # @return [Integer] length of the string after it was modified
      def setrange(key, offset, value)
        send_command([:setrange, key, Integer(offset), value.to_s])
      end

      # Get a substring of the string stored at a key.
      #
      # @param [String] key
      # @param [Integer] start zero-based start offset
      # @param [Integer] stop zero-based end offset. Use -1 for representing
      #   the end of the string
      # @return [Integer] `0` or `1`
      def getrange(key, start, stop)
        send_command([:getrange, key, Integer(start), Integer(stop)])
      end

      # Append a value to a key.
      #
      # @param [String] key
      # @param [String] value value to append
      # @return [Integer] length of the string after appending
      def append(key, value)
        send_command([:append, key, value])
      end

      # Set the string value of a key and return its old value.
      #
      # @param [String] key
      # @param [String] value value to replace the current value with
      # @return [String] the old value stored in the key, or `nil` if the key
      #   did not exist
      def getset(key, value)
        send_command([:getset, key, value.to_s])
      end

      # Get the value of key and delete the key. This command is similar to GET,
      # except for the fact that it also deletes the key on success.
      #
      # @param [String] key
      # @return [String] the old value stored in the key, or `nil` if the key
      #   did not exist
      def getdel(key)
        send_command([:getdel, key])
      end

      # Get the value of key and optionally set its expiration. GETEX is similar to
      # GET, but is a write command with additional options. When no options are
      # provided, GETEX behaves like GET.
      #
      # @param [String] key
      # @param [Hash] options
      #   - `:ex => Integer`: Set the specified expire time, in seconds.
      #   - `:px => Integer`: Set the specified expire time, in milliseconds.
      #   - `:exat => true`: Set the specified Unix time at which the key will
      #      expire, in seconds.
      #   - `:pxat => true`: Set the specified Unix time at which the key will
      #      expire, in milliseconds.
      #   - `:persist => true`: Remove the time to live associated with the key.
      # @return [String] The value of key, or nil when key does not exist.
      def getex(key, ex: nil, px: nil, exat: nil, pxat: nil, persist: false)
        args = [:getex, key]
        args << "EX" << Integer(ex) if ex
        args << "PX" << Integer(px) if px
        args << "EXAT" << Integer(exat) if exat
        args << "PXAT" << Integer(pxat) if pxat
        args << "PERSIST" if persist

        send_command(args)
      end

      # Get the length of the value stored in a key.
      #
      # @param [String] key
      # @return [Integer] the length of the value stored in the key, or 0
      #   if the key does not exist
      def strlen(key)
        send_command([:strlen, key])
      end
    end
  end
end
