# frozen_string_literal: true

class Redis
  module Commands
    module Hashes
      # Get the number of fields in a hash.
      #
      # @param [String] key
      # @return [Integer] number of fields in the hash
      def hlen(key)
        send_command([:hlen, key])
      end

      # Set one or more hash values.
      #
      # @example
      #   redis.hset("hash", "f1", "v1", "f2", "v2") # => 2
      #   redis.hset("hash", { "f1" => "v1", "f2" => "v2" }) # => 2
      #
      # @param [String] key
      # @param [Array<String> | Hash<String, String>] attrs array or hash of fields and values
      # @return [Integer] The number of fields that were added to the hash
      def hset(key, *attrs)
        attrs = attrs.first.flatten if attrs.size == 1 && attrs.first.is_a?(Hash)

        send_command([:hset, key, *attrs])
      end

      # Set the value of a hash field, only if the field does not exist.
      #
      # @param [String] key
      # @param [String] field
      # @param [String] value
      # @return [Boolean] whether or not the field was **added** to the hash
      def hsetnx(key, field, value)
        send_command([:hsetnx, key, field, value], &Boolify)
      end

      # Set one or more hash values.
      #
      # @example
      #   redis.hmset("hash", "f1", "v1", "f2", "v2")
      #     # => "OK"
      #
      # @param [String] key
      # @param [Array<String>] attrs array of fields and values
      # @return [String] `"OK"`
      #
      # @see #mapped_hmset
      def hmset(key, *attrs)
        send_command([:hmset, key] + attrs)
      end

      # Set one or more hash values.
      #
      # @example
      #   redis.mapped_hmset("hash", { "f1" => "v1", "f2" => "v2" })
      #     # => "OK"
      #
      # @param [String] key
      # @param [Hash] hash a non-empty hash with fields mapping to values
      # @return [String] `"OK"`
      #
      # @see #hmset
      def mapped_hmset(key, hash)
        hmset(key, hash.flatten)
      end

      # Get the value of a hash field.
      #
      # @param [String] key
      # @param [String] field
      # @return [String]
      def hget(key, field)
        send_command([:hget, key, field])
      end

      # Get the values of all the given hash fields.
      #
      # @example
      #   redis.hmget("hash", "f1", "f2")
      #     # => ["v1", "v2"]
      #
      # @param [String] key
      # @param [Array<String>] fields array of fields
      # @return [Array<String>] an array of values for the specified fields
      #
      # @see #mapped_hmget
      def hmget(key, *fields, &blk)
        fields.flatten!(1)
        send_command([:hmget, key].concat(fields), &blk)
      end

      # Get the values of all the given hash fields.
      #
      # @example
      #   redis.mapped_hmget("hash", "f1", "f2")
      #     # => { "f1" => "v1", "f2" => "v2" }
      #
      # @param [String] key
      # @param [Array<String>] fields array of fields
      # @return [Hash] a hash mapping the specified fields to their values
      #
      # @see #hmget
      def mapped_hmget(key, *fields)
        fields.flatten!(1)
        hmget(key, fields) do |reply|
          if reply.is_a?(Array)
            Hash[fields.zip(reply)]
          else
            reply
          end
        end
      end

      # Get one or more random fields from a hash.
      #
      # @example Get one random field
      #   redis.hrandfield("hash")
      #     # => "f1"
      # @example Get multiple random fields
      #   redis.hrandfield("hash", 2)
      #     # => ["f1, "f2"]
      # @example Get multiple random fields with values
      #   redis.hrandfield("hash", 2, with_values: true)
      #     # => [["f1", "s1"], ["f2", "s2"]]
      #
      # @param [String] key
      # @param [Integer] count
      # @param [Hash] options
      #   - `:with_values => true`: include values in output
      #
      # @return [nil, String, Array<String>, Array<[String, Float]>]
      #   - when `key` does not exist, `nil`
      #   - when `count` is not specified, a field name
      #   - when `count` is specified and `:with_values` is not specified, an array of field names
      #   - when `:with_values` is specified, an array with `[field, value]` pairs
      def hrandfield(key, count = nil, withvalues: false, with_values: withvalues)
        if with_values && count.nil?
          raise ArgumentError, "count argument must be specified"
        end

        args = [:hrandfield, key]
        args << count if count
        args << "WITHVALUES" if with_values

        parser = Pairify if with_values
        send_command(args, &parser)
      end

      # Delete one or more hash fields.
      #
      # @param [String] key
      # @param [String, Array<String>] field
      # @return [Integer] the number of fields that were removed from the hash
      def hdel(key, *fields)
        fields.flatten!(1)
        send_command([:hdel, key].concat(fields))
      end

      # Determine if a hash field exists.
      #
      # @param [String] key
      # @param [String] field
      # @return [Boolean] whether or not the field exists in the hash
      def hexists(key, field)
        send_command([:hexists, key, field], &Boolify)
      end

      # Increment the integer value of a hash field by the given integer number.
      #
      # @param [String] key
      # @param [String] field
      # @param [Integer] increment
      # @return [Integer] value of the field after incrementing it
      def hincrby(key, field, increment)
        send_command([:hincrby, key, field, Integer(increment)])
      end

      # Increment the numeric value of a hash field by the given float number.
      #
      # @param [String] key
      # @param [String] field
      # @param [Float] increment
      # @return [Float] value of the field after incrementing it
      def hincrbyfloat(key, field, increment)
        send_command([:hincrbyfloat, key, field, Float(increment)], &Floatify)
      end

      # Get all the fields in a hash.
      #
      # @param [String] key
      # @return [Array<String>]
      def hkeys(key)
        send_command([:hkeys, key])
      end

      # Get all the values in a hash.
      #
      # @param [String] key
      # @return [Array<String>]
      def hvals(key)
        send_command([:hvals, key])
      end

      # Get all the fields and values in a hash.
      #
      # @param [String] key
      # @return [Hash<String, String>]
      def hgetall(key)
        send_command([:hgetall, key], &Hashify)
      end

      # Scan a hash
      #
      # @example Retrieve the first batch of key/value pairs in a hash
      #   redis.hscan("hash", 0)
      #
      # @param [String, Integer] cursor the cursor of the iteration
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #
      # @return [String, Array<[String, String]>] the next cursor and all found keys
      def hscan(key, cursor, **options)
        _scan(:hscan, cursor, [key], **options) do |reply|
          [reply[0], reply[1].each_slice(2).to_a]
        end
      end

      # Scan a hash
      #
      # @example Retrieve all of the key/value pairs in a hash
      #   redis.hscan_each("hash").to_a
      #   # => [["key70", "70"], ["key80", "80"]]
      #
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #
      # @return [Enumerator] an enumerator for all found keys
      def hscan_each(key, **options, &block)
        return to_enum(:hscan_each, key, **options) unless block_given?

        cursor = 0
        loop do
          cursor, values = hscan(key, cursor, **options)
          values.each(&block)
          break if cursor == "0"
        end
      end
    end
  end
end
