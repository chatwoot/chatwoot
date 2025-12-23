# frozen_string_literal: true

class Redis
  module Commands
    module Keys
      # Scan the keyspace
      #
      # @example Retrieve the first batch of keys
      #   redis.scan(0)
      #     # => ["4", ["key:21", "key:47", "key:42"]]
      # @example Retrieve a batch of keys matching a pattern
      #   redis.scan(4, :match => "key:1?")
      #     # => ["92", ["key:13", "key:18"]]
      # @example Retrieve a batch of keys of a certain type
      #   redis.scan(92, :type => "zset")
      #     # => ["173", ["sortedset:14", "sortedset:78"]]
      #
      # @param [String, Integer] cursor the cursor of the iteration
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #   - `:type => String`: return keys only of the given type
      #
      # @return [String, Array<String>] the next cursor and all found keys
      def scan(cursor, **options)
        _scan(:scan, cursor, [], **options)
      end

      # Scan the keyspace
      #
      # @example Retrieve all of the keys (with possible duplicates)
      #   redis.scan_each.to_a
      #     # => ["key:21", "key:47", "key:42"]
      # @example Execute block for each key matching a pattern
      #   redis.scan_each(:match => "key:1?") {|key| puts key}
      #     # => key:13
      #     # => key:18
      # @example Execute block for each key of a type
      #   redis.scan_each(:type => "hash") {|key| puts redis.type(key)}
      #     # => "hash"
      #     # => "hash"
      #
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #   - `:type => String`: return keys only of the given type
      #
      # @return [Enumerator] an enumerator for all found keys
      def scan_each(**options, &block)
        return to_enum(:scan_each, **options) unless block_given?

        cursor = 0
        loop do
          cursor, keys = scan(cursor, **options)
          keys.each(&block)
          break if cursor == "0"
        end
      end

      # Remove the expiration from a key.
      #
      # @param [String] key
      # @return [Boolean] whether the timeout was removed or not
      def persist(key)
        send_command([:persist, key], &Boolify)
      end

      # Set a key's time to live in seconds.
      #
      # @param [String] key
      # @param [Integer] seconds time to live
      # @param [Hash] options
      #   - `:nx => true`: Set expiry only when the key has no expiry.
      #   - `:xx => true`: Set expiry only when the key has an existing expiry.
      #   - `:gt => true`: Set expiry only when the new expiry is greater than current one.
      #   - `:lt => true`: Set expiry only when the new expiry is less than current one.
      # @return [Boolean] whether the timeout was set or not
      def expire(key, seconds, nx: nil, xx: nil, gt: nil, lt: nil)
        args = [:expire, key, Integer(seconds)]
        args << "NX" if nx
        args << "XX" if xx
        args << "GT" if gt
        args << "LT" if lt

        send_command(args, &Boolify)
      end

      # Set the expiration for a key as a UNIX timestamp.
      #
      # @param [String] key
      # @param [Integer] unix_time expiry time specified as a UNIX timestamp
      # @param [Hash] options
      #   - `:nx => true`: Set expiry only when the key has no expiry.
      #   - `:xx => true`: Set expiry only when the key has an existing expiry.
      #   - `:gt => true`: Set expiry only when the new expiry is greater than current one.
      #   - `:lt => true`: Set expiry only when the new expiry is less than current one.
      # @return [Boolean] whether the timeout was set or not
      def expireat(key, unix_time, nx: nil, xx: nil, gt: nil, lt: nil)
        args = [:expireat, key, Integer(unix_time)]
        args << "NX" if nx
        args << "XX" if xx
        args << "GT" if gt
        args << "LT" if lt

        send_command(args, &Boolify)
      end

      # Get the time to live (in seconds) for a key.
      #
      # @param [String] key
      # @return [Integer] remaining time to live in seconds.
      #
      # In Redis 2.6 or older the command returns -1 if the key does not exist or if
      # the key exist but has no associated expire.
      #
      # Starting with Redis 2.8 the return value in case of error changed:
      #
      #     - The command returns -2 if the key does not exist.
      #     - The command returns -1 if the key exists but has no associated expire.
      def ttl(key)
        send_command([:ttl, key])
      end

      # Set a key's time to live in milliseconds.
      #
      # @param [String] key
      # @param [Integer] milliseconds time to live
      # @param [Hash] options
      #   - `:nx => true`: Set expiry only when the key has no expiry.
      #   - `:xx => true`: Set expiry only when the key has an existing expiry.
      #   - `:gt => true`: Set expiry only when the new expiry is greater than current one.
      #   - `:lt => true`: Set expiry only when the new expiry is less than current one.
      # @return [Boolean] whether the timeout was set or not
      def pexpire(key, milliseconds, nx: nil, xx: nil, gt: nil, lt: nil)
        args = [:pexpire, key, Integer(milliseconds)]
        args << "NX" if nx
        args << "XX" if xx
        args << "GT" if gt
        args << "LT" if lt

        send_command(args, &Boolify)
      end

      # Set the expiration for a key as number of milliseconds from UNIX Epoch.
      #
      # @param [String] key
      # @param [Integer] ms_unix_time expiry time specified as number of milliseconds from UNIX Epoch.
      # @param [Hash] options
      #   - `:nx => true`: Set expiry only when the key has no expiry.
      #   - `:xx => true`: Set expiry only when the key has an existing expiry.
      #   - `:gt => true`: Set expiry only when the new expiry is greater than current one.
      #   - `:lt => true`: Set expiry only when the new expiry is less than current one.
      # @return [Boolean] whether the timeout was set or not
      def pexpireat(key, ms_unix_time, nx: nil, xx: nil, gt: nil, lt: nil)
        args = [:pexpireat, key, Integer(ms_unix_time)]
        args << "NX" if nx
        args << "XX" if xx
        args << "GT" if gt
        args << "LT" if lt

        send_command(args, &Boolify)
      end

      # Get the time to live (in milliseconds) for a key.
      #
      # @param [String] key
      # @return [Integer] remaining time to live in milliseconds
      # In Redis 2.6 or older the command returns -1 if the key does not exist or if
      # the key exist but has no associated expire.
      #
      # Starting with Redis 2.8 the return value in case of error changed:
      #
      #     - The command returns -2 if the key does not exist.
      #     - The command returns -1 if the key exists but has no associated expire.
      def pttl(key)
        send_command([:pttl, key])
      end

      # Return a serialized version of the value stored at a key.
      #
      # @param [String] key
      # @return [String] serialized_value
      def dump(key)
        send_command([:dump, key])
      end

      # Create a key using the serialized value, previously obtained using DUMP.
      #
      # @param [String] key
      # @param [String] ttl
      # @param [String] serialized_value
      # @param [Hash] options
      #   - `:replace => Boolean`: if false, raises an error if key already exists
      # @raise [Redis::CommandError]
      # @return [String] `"OK"`
      def restore(key, ttl, serialized_value, replace: nil)
        args = [:restore, key, ttl, serialized_value]
        args << 'REPLACE' if replace

        send_command(args)
      end

      # Transfer a key from the connected instance to another instance.
      #
      # @param [String, Array<String>] key
      # @param [Hash] options
      #   - `:host => String`: host of instance to migrate to
      #   - `:port => Integer`: port of instance to migrate to
      #   - `:db => Integer`: database to migrate to (default: same as source)
      #   - `:timeout => Integer`: timeout (default: same as connection timeout)
      #   - `:copy => Boolean`: Do not remove the key from the local instance.
      #   - `:replace => Boolean`: Replace existing key on the remote instance.
      # @return [String] `"OK"`
      def migrate(key, options)
        args = [:migrate]
        args << (options[:host] || raise(':host not specified'))
        args << (options[:port] || raise(':port not specified'))
        args << (key.is_a?(String) ? key : '')
        args << (options[:db] || @client.db).to_i
        args << (options[:timeout] || @client.timeout).to_i
        args << 'COPY' if options[:copy]
        args << 'REPLACE' if options[:replace]
        args += ['KEYS', *key] if key.is_a?(Array)

        send_command(args)
      end

      # Delete one or more keys.
      #
      # @param [String, Array<String>] keys
      # @return [Integer] number of keys that were deleted
      def del(*keys)
        keys.flatten!(1)
        return 0 if keys.empty?

        send_command([:del] + keys)
      end

      # Unlink one or more keys.
      #
      # @param [String, Array<String>] keys
      # @return [Integer] number of keys that were unlinked
      def unlink(*keys)
        send_command([:unlink] + keys)
      end

      # Determine how many of the keys exists.
      #
      # @param [String, Array<String>] keys
      # @return [Integer]
      def exists(*keys)
        send_command([:exists, *keys])
      end

      # Determine if any of the keys exists.
      #
      # @param [String, Array<String>] keys
      # @return [Boolean]
      def exists?(*keys)
        send_command([:exists, *keys]) do |value|
          value > 0
        end
      end

      # Find all keys matching the given pattern.
      #
      # @param [String] pattern
      # @return [Array<String>]
      def keys(pattern = "*")
        send_command([:keys, pattern]) do |reply|
          if reply.is_a?(String)
            reply.split(" ")
          else
            reply
          end
        end
      end

      # Move a key to another database.
      #
      # @example Move a key to another database
      #   redis.set "foo", "bar"
      #     # => "OK"
      #   redis.move "foo", 2
      #     # => true
      #   redis.exists "foo"
      #     # => false
      #   redis.select 2
      #     # => "OK"
      #   redis.exists "foo"
      #     # => true
      #   redis.get "foo"
      #     # => "bar"
      #
      # @param [String] key
      # @param [Integer] db
      # @return [Boolean] whether the key was moved or not
      def move(key, db)
        send_command([:move, key, db], &Boolify)
      end

      # Copy a value from one key to another.
      #
      # @example Copy a value to another key
      #   redis.set "foo", "value"
      #     # => "OK"
      #   redis.copy "foo", "bar"
      #     # => true
      #   redis.get "bar"
      #     # => "value"
      #
      # @example Copy a value to a key in another database
      #   redis.set "foo", "value"
      #     # => "OK"
      #   redis.copy "foo", "bar", db: 2
      #     # => true
      #   redis.select 2
      #     # => "OK"
      #   redis.get "bar"
      #     # => "value"
      #
      # @param [String] source
      # @param [String] destination
      # @param [Integer] db
      # @param [Boolean] replace removes the `destination` key before copying value to it
      # @return [Boolean] whether the key was copied or not
      def copy(source, destination, db: nil, replace: false)
        command = [:copy, source, destination]
        command << "DB" << db if db
        command << "REPLACE" if replace

        send_command(command, &Boolify)
      end

      def object(*args)
        send_command([:object] + args)
      end

      # Return a random key from the keyspace.
      #
      # @return [String]
      def randomkey
        send_command([:randomkey])
      end

      # Rename a key. If the new key already exists it is overwritten.
      #
      # @param [String] old_name
      # @param [String] new_name
      # @return [String] `OK`
      def rename(old_name, new_name)
        send_command([:rename, old_name, new_name])
      end

      # Rename a key, only if the new key does not exist.
      #
      # @param [String] old_name
      # @param [String] new_name
      # @return [Boolean] whether the key was renamed or not
      def renamenx(old_name, new_name)
        send_command([:renamenx, old_name, new_name], &Boolify)
      end

      # Sort the elements in a list, set or sorted set.
      #
      # @example Retrieve the first 2 elements from an alphabetically sorted "list"
      #   redis.sort("list", :order => "alpha", :limit => [0, 2])
      #     # => ["a", "b"]
      # @example Store an alphabetically descending list in "target"
      #   redis.sort("list", :order => "desc alpha", :store => "target")
      #     # => 26
      #
      # @param [String] key
      # @param [Hash] options
      #   - `:by => String`: use external key to sort elements by
      #   - `:limit => [offset, count]`: skip `offset` elements, return a maximum
      #   of `count` elements
      #   - `:get => [String, Array<String>]`: single key or array of keys to
      #   retrieve per element in the result
      #   - `:order => String`: combination of `ASC`, `DESC` and optionally `ALPHA`
      #   - `:store => String`: key to store the result at
      #
      # @return [Array<String>, Array<Array<String>>, Integer]
      #   - when `:get` is not specified, or holds a single element, an array of elements
      #   - when `:get` is specified, and holds more than one element, an array of
      #   elements where every element is an array with the result for every
      #   element specified in `:get`
      #   - when `:store` is specified, the number of elements in the stored result
      def sort(key, by: nil, limit: nil, get: nil, order: nil, store: nil)
        args = [:sort, key]
        args << "BY" << by if by

        if limit
          args << "LIMIT"
          args.concat(limit)
        end

        get = Array(get)
        get.each do |item|
          args << "GET" << item
        end

        args.concat(order.split(" ")) if order
        args << "STORE" << store if store

        send_command(args) do |reply|
          if get.size > 1 && !store
            reply.each_slice(get.size).to_a if reply
          else
            reply
          end
        end
      end

      # Determine the type stored at key.
      #
      # @param [String] key
      # @return [String] `string`, `list`, `set`, `zset`, `hash` or `none`
      def type(key)
        send_command([:type, key])
      end

      private

      def _scan(command, cursor, args, match: nil, count: nil, type: nil, &block)
        # SSCAN/ZSCAN/HSCAN already prepend the key to +args+.

        args << cursor
        args << "MATCH" << match if match
        args << "COUNT" << Integer(count) if count
        args << "TYPE" << type if type

        send_command([command] + args, &block)
      end
    end
  end
end
