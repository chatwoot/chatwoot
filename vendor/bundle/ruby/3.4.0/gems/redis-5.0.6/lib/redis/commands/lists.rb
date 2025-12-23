# frozen_string_literal: true

class Redis
  module Commands
    module Lists
      # Get the length of a list.
      #
      # @param [String] key
      # @return [Integer]
      def llen(key)
        send_command([:llen, key])
      end

      # Remove the first/last element in a list, append/prepend it to another list and return it.
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @param [String, Symbol] where_source from where to remove the element from the source list
      #     e.g. 'LEFT' - from head, 'RIGHT' - from tail
      # @param [String, Symbol] where_destination where to push the element to the source list
      #     e.g. 'LEFT' - to head, 'RIGHT' - to tail
      #
      # @return [nil, String] the element, or nil when the source key does not exist
      #
      # @note This command comes in place of the now deprecated RPOPLPUSH.
      #     Doing LMOVE RIGHT LEFT is equivalent.
      def lmove(source, destination, where_source, where_destination)
        where_source, where_destination = _normalize_move_wheres(where_source, where_destination)

        send_command([:lmove, source, destination, where_source, where_destination])
      end

      # Remove the first/last element in a list and append/prepend it
      # to another list and return it, or block until one is available.
      #
      # @example With timeout
      #   element = redis.blmove("foo", "bar", "LEFT", "RIGHT", timeout: 5)
      #     # => nil on timeout
      #     # => "element" on success
      # @example Without timeout
      #   element = redis.blmove("foo", "bar", "LEFT", "RIGHT")
      #     # => "element"
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @param [String, Symbol] where_source from where to remove the element from the source list
      #     e.g. 'LEFT' - from head, 'RIGHT' - from tail
      # @param [String, Symbol] where_destination where to push the element to the source list
      #     e.g. 'LEFT' - to head, 'RIGHT' - to tail
      # @param [Hash] options
      #   - `:timeout => [Float, Integer]`: timeout in seconds, defaults to no timeout
      #
      # @return [nil, String] the element, or nil when the source key does not exist or the timeout expired
      #
      def blmove(source, destination, where_source, where_destination, timeout: 0)
        where_source, where_destination = _normalize_move_wheres(where_source, where_destination)

        command = [:blmove, source, destination, where_source, where_destination, timeout]
        send_blocking_command(command, timeout)
      end

      # Prepend one or more values to a list, creating the list if it doesn't exist
      #
      # @param [String] key
      # @param [String, Array<String>] value string value, or array of string values to push
      # @return [Integer] the length of the list after the push operation
      def lpush(key, value)
        send_command([:lpush, key, value])
      end

      # Prepend a value to a list, only if the list exists.
      #
      # @param [String] key
      # @param [String] value
      # @return [Integer] the length of the list after the push operation
      def lpushx(key, value)
        send_command([:lpushx, key, value])
      end

      # Append one or more values to a list, creating the list if it doesn't exist
      #
      # @param [String] key
      # @param [String, Array<String>] value string value, or array of string values to push
      # @return [Integer] the length of the list after the push operation
      def rpush(key, value)
        send_command([:rpush, key, value])
      end

      # Append a value to a list, only if the list exists.
      #
      # @param [String] key
      # @param [String] value
      # @return [Integer] the length of the list after the push operation
      def rpushx(key, value)
        send_command([:rpushx, key, value])
      end

      # Remove and get the first elements in a list.
      #
      # @param [String] key
      # @param [Integer] count number of elements to remove
      # @return [nil, String, Array<String>] the values of the first elements
      def lpop(key, count = nil)
        command = [:lpop, key]
        command << Integer(count) if count
        send_command(command)
      end

      # Remove and get the last elements in a list.
      #
      # @param [String] key
      # @param [Integer] count number of elements to remove
      # @return [nil, String, Array<String>] the values of the last elements
      def rpop(key, count = nil)
        command = [:rpop, key]
        command << Integer(count) if count
        send_command(command)
      end

      # Remove the last element in a list, append it to another list and return it.
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @return [nil, String] the element, or nil when the source key does not exist
      def rpoplpush(source, destination)
        send_command([:rpoplpush, source, destination])
      end

      # Remove and get the first element in a list, or block until one is available.
      #
      # @example With timeout
      #   list, element = redis.blpop("list", :timeout => 5)
      #     # => nil on timeout
      #     # => ["list", "element"] on success
      # @example Without timeout
      #   list, element = redis.blpop("list")
      #     # => ["list", "element"]
      # @example Blocking pop on multiple lists
      #   list, element = redis.blpop(["list", "another_list"])
      #     # => ["list", "element"]
      #
      # @param [String, Array<String>] keys one or more keys to perform the
      #   blocking pop on
      # @param [Hash] options
      #   - `:timeout => [Float, Integer]`: timeout in seconds, defaults to no timeout
      #
      # @return [nil, [String, String]]
      #   - `nil` when the operation timed out
      #   - tuple of the list that was popped from and element was popped otherwise
      def blpop(*args)
        _bpop(:blpop, args)
      end

      # Remove and get the last element in a list, or block until one is available.
      #
      # @param [String, Array<String>] keys one or more keys to perform the
      #   blocking pop on
      # @param [Hash] options
      #   - `:timeout => [Float, Integer]`: timeout in seconds, defaults to no timeout
      #
      # @return [nil, [String, String]]
      #   - `nil` when the operation timed out
      #   - tuple of the list that was popped from and element was popped otherwise
      #
      # @see #blpop
      def brpop(*args)
        _bpop(:brpop, args)
      end

      # Pop a value from a list, push it to another list and return it; or block
      # until one is available.
      #
      # @param [String] source source key
      # @param [String] destination destination key
      # @param [Hash] options
      #   - `:timeout => [Float, Integer]`: timeout in seconds, defaults to no timeout
      #
      # @return [nil, String]
      #   - `nil` when the operation timed out
      #   - the element was popped and pushed otherwise
      def brpoplpush(source, destination, timeout: 0)
        command = [:brpoplpush, source, destination, timeout]
        send_blocking_command(command, timeout)
      end

      # Get an element from a list by its index.
      #
      # @param [String] key
      # @param [Integer] index
      # @return [String]
      def lindex(key, index)
        send_command([:lindex, key, Integer(index)])
      end

      # Insert an element before or after another element in a list.
      #
      # @param [String] key
      # @param [String, Symbol] where `BEFORE` or `AFTER`
      # @param [String] pivot reference element
      # @param [String] value
      # @return [Integer] length of the list after the insert operation, or `-1`
      #   when the element `pivot` was not found
      def linsert(key, where, pivot, value)
        send_command([:linsert, key, where, pivot, value])
      end

      # Get a range of elements from a list.
      #
      # @param [String] key
      # @param [Integer] start start index
      # @param [Integer] stop stop index
      # @return [Array<String>]
      def lrange(key, start, stop)
        send_command([:lrange, key, Integer(start), Integer(stop)])
      end

      # Remove elements from a list.
      #
      # @param [String] key
      # @param [Integer] count number of elements to remove. Use a positive
      #   value to remove the first `count` occurrences of `value`. A negative
      #   value to remove the last `count` occurrences of `value`. Or zero, to
      #   remove all occurrences of `value` from the list.
      # @param [String] value
      # @return [Integer] the number of removed elements
      def lrem(key, count, value)
        send_command([:lrem, key, Integer(count), value])
      end

      # Set the value of an element in a list by its index.
      #
      # @param [String] key
      # @param [Integer] index
      # @param [String] value
      # @return [String] `OK`
      def lset(key, index, value)
        send_command([:lset, key, Integer(index), value])
      end

      # Trim a list to the specified range.
      #
      # @param [String] key
      # @param [Integer] start start index
      # @param [Integer] stop stop index
      # @return [String] `OK`
      def ltrim(key, start, stop)
        send_command([:ltrim, key, Integer(start), Integer(stop)])
      end

      private

      def _bpop(cmd, args, &blk)
        timeout = if args.last.is_a?(Hash)
          options = args.pop
          options[:timeout]
        end

        timeout ||= 0
        unless timeout.is_a?(Integer) || timeout.is_a?(Float)
          raise ArgumentError, "timeout must be an Integer or Float, got: #{timeout.class}"
        end

        args.flatten!(1)
        command = [cmd].concat(args)
        command << timeout
        send_blocking_command(command, timeout, &blk)
      end

      def _normalize_move_wheres(where_source, where_destination)
        where_source      = where_source.to_s.upcase
        where_destination = where_destination.to_s.upcase

        if where_source != "LEFT" && where_source != "RIGHT"
          raise ArgumentError, "where_source must be 'LEFT' or 'RIGHT'"
        end

        if where_destination != "LEFT" && where_destination != "RIGHT"
          raise ArgumentError, "where_destination must be 'LEFT' or 'RIGHT'"
        end

        [where_source, where_destination]
      end
    end
  end
end
