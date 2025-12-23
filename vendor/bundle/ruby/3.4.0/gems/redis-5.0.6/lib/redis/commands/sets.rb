# frozen_string_literal: true

class Redis
  module Commands
    module Sets
      # Get the number of members in a set.
      #
      # @param [String] key
      # @return [Integer]
      def scard(key)
        send_command([:scard, key])
      end

      # Add one or more members to a set.
      #
      # @param [String] key
      # @param [String, Array<String>] member one member, or array of members
      # @return [Integer] The number of members that were successfully added
      def sadd(key, *members)
        members.flatten!(1)
        send_command([:sadd, key].concat(members))
      end

      # Add one or more members to a set.
      #
      # @param [String] key
      # @param [String, Array<String>] member one member, or array of members
      # @return [Boolean] Wether at least one member was successfully added.
      def sadd?(key, *members)
        members.flatten!(1)
        send_command([:sadd, key].concat(members), &Boolify)
      end

      # Remove one or more members from a set.
      #
      # @param [String] key
      # @param [String, Array<String>] member one member, or array of members
      # @return [Integer] The number of members that were successfully removed
      def srem(key, *members)
        members.flatten!(1)
        send_command([:srem, key].concat(members))
      end

      # Remove one or more members from a set.
      #
      # @param [String] key
      # @param [String, Array<String>] member one member, or array of members
      # @return [Boolean] Wether at least one member was successfully removed.
      def srem?(key, *members)
        members.flatten!(1)
        send_command([:srem, key].concat(members), &Boolify)
      end

      # Remove and return one or more random member from a set.
      #
      # @param [String] key
      # @return [String]
      # @param [Integer] count
      def spop(key, count = nil)
        if count.nil?
          send_command([:spop, key])
        else
          send_command([:spop, key, Integer(count)])
        end
      end

      # Get one or more random members from a set.
      #
      # @param [String] key
      # @param [Integer] count
      # @return [String]
      def srandmember(key, count = nil)
        if count.nil?
          send_command([:srandmember, key])
        else
          send_command([:srandmember, key, count])
        end
      end

      # Move a member from one set to another.
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @param [String] member member to move from `source` to `destination`
      # @return [Boolean]
      def smove(source, destination, member)
        send_command([:smove, source, destination, member], &Boolify)
      end

      # Determine if a given value is a member of a set.
      #
      # @param [String] key
      # @param [String] member
      # @return [Boolean]
      def sismember(key, member)
        send_command([:sismember, key, member], &Boolify)
      end

      # Determine if multiple values are members of a set.
      #
      # @param [String] key
      # @param [String, Array<String>] members
      # @return [Array<Boolean>]
      def smismember(key, *members)
        members.flatten!(1)
        send_command([:smismember, key].concat(members)) do |reply|
          reply.map(&Boolify)
        end
      end

      # Get all the members in a set.
      #
      # @param [String] key
      # @return [Array<String>]
      def smembers(key)
        send_command([:smembers, key])
      end

      # Subtract multiple sets.
      #
      # @param [String, Array<String>] keys keys pointing to sets to subtract
      # @return [Array<String>] members in the difference
      def sdiff(*keys)
        keys.flatten!(1)
        send_command([:sdiff].concat(keys))
      end

      # Subtract multiple sets and store the resulting set in a key.
      #
      # @param [String] destination destination key
      # @param [String, Array<String>] keys keys pointing to sets to subtract
      # @return [Integer] number of elements in the resulting set
      def sdiffstore(destination, *keys)
        keys.flatten!(1)
        send_command([:sdiffstore, destination].concat(keys))
      end

      # Intersect multiple sets.
      #
      # @param [String, Array<String>] keys keys pointing to sets to intersect
      # @return [Array<String>] members in the intersection
      def sinter(*keys)
        keys.flatten!(1)
        send_command([:sinter].concat(keys))
      end

      # Intersect multiple sets and store the resulting set in a key.
      #
      # @param [String] destination destination key
      # @param [String, Array<String>] keys keys pointing to sets to intersect
      # @return [Integer] number of elements in the resulting set
      def sinterstore(destination, *keys)
        keys.flatten!(1)
        send_command([:sinterstore, destination].concat(keys))
      end

      # Add multiple sets.
      #
      # @param [String, Array<String>] keys keys pointing to sets to unify
      # @return [Array<String>] members in the union
      def sunion(*keys)
        keys.flatten!(1)
        send_command([:sunion].concat(keys))
      end

      # Add multiple sets and store the resulting set in a key.
      #
      # @param [String] destination destination key
      # @param [String, Array<String>] keys keys pointing to sets to unify
      # @return [Integer] number of elements in the resulting set
      def sunionstore(destination, *keys)
        keys.flatten!(1)
        send_command([:sunionstore, destination].concat(keys))
      end

      # Scan a set
      #
      # @example Retrieve the first batch of keys in a set
      #   redis.sscan("set", 0)
      #
      # @param [String, Integer] cursor the cursor of the iteration
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #
      # @return [String, Array<String>] the next cursor and all found members
      def sscan(key, cursor, **options)
        _scan(:sscan, cursor, [key], **options)
      end

      # Scan a set
      #
      # @example Retrieve all of the keys in a set
      #   redis.sscan_each("set").to_a
      #   # => ["key1", "key2", "key3"]
      #
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #
      # @return [Enumerator] an enumerator for all keys in the set
      def sscan_each(key, **options, &block)
        return to_enum(:sscan_each, key, **options) unless block_given?

        cursor = 0
        loop do
          cursor, keys = sscan(key, cursor, **options)
          keys.each(&block)
          break if cursor == "0"
        end
      end
    end
  end
end
