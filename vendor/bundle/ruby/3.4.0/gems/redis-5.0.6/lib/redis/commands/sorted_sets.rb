# frozen_string_literal: true

class Redis
  module Commands
    module SortedSets
      # Get the number of members in a sorted set.
      #
      # @example
      #   redis.zcard("zset")
      #     # => 4
      #
      # @param [String] key
      # @return [Integer]
      def zcard(key)
        send_command([:zcard, key])
      end

      # Add one or more members to a sorted set, or update the score for members
      # that already exist.
      #
      # @example Add a single `[score, member]` pair to a sorted set
      #   redis.zadd("zset", 32.0, "member")
      # @example Add an array of `[score, member]` pairs to a sorted set
      #   redis.zadd("zset", [[32.0, "a"], [64.0, "b"]])
      #
      # @param [String] key
      # @param [[Float, String], Array<[Float, String]>] args
      #   - a single `[score, member]` pair
      #   - an array of `[score, member]` pairs
      # @param [Hash] options
      #   - `:xx => true`: Only update elements that already exist (never
      #   add elements)
      #   - `:nx => true`: Don't update already existing elements (always
      #   add new elements)
      #   - `:lt => true`: Only update existing elements if the new score
      #   is less than the current score
      #   - `:gt => true`: Only update existing elements if the new score
      #   is greater than the current score
      #   - `:ch => true`: Modify the return value from the number of new
      #   elements added, to the total number of elements changed (CH is an
      #   abbreviation of changed); changed elements are new elements added
      #   and elements already existing for which the score was updated
      #   - `:incr => true`: When this option is specified ZADD acts like
      #   ZINCRBY; only one score-element pair can be specified in this mode
      #
      # @return [Boolean, Integer, Float]
      #   - `Boolean` when a single pair is specified, holding whether or not it was
      #   **added** to the sorted set.
      #   - `Integer` when an array of pairs is specified, holding the number of
      #   pairs that were **added** to the sorted set.
      #   - `Float` when option :incr is specified, holding the score of the member
      #   after incrementing it.
      def zadd(key, *args, nx: nil, xx: nil, lt: nil, gt: nil, ch: nil, incr: nil)
        command = [:zadd, key]
        command << "NX" if nx
        command << "XX" if xx
        command << "LT" if lt
        command << "GT" if gt
        command << "CH" if ch
        command << "INCR" if incr

        if args.size == 1 && args[0].is_a?(Array)
          members_to_add = args[0]
          return 0 if members_to_add.empty?

          # Variadic: return float if INCR, integer if !INCR
          send_command(command + members_to_add, &(incr ? Floatify : nil))
        elsif args.size == 2
          # Single pair: return float if INCR, boolean if !INCR
          send_command(command + args, &(incr ? Floatify : Boolify))
        else
          raise ArgumentError, "wrong number of arguments"
        end
      end

      # Increment the score of a member in a sorted set.
      #
      # @example
      #   redis.zincrby("zset", 32.0, "a")
      #     # => 64.0
      #
      # @param [String] key
      # @param [Float] increment
      # @param [String] member
      # @return [Float] score of the member after incrementing it
      def zincrby(key, increment, member)
        send_command([:zincrby, key, increment, member], &Floatify)
      end

      # Remove one or more members from a sorted set.
      #
      # @example Remove a single member from a sorted set
      #   redis.zrem("zset", "a")
      # @example Remove an array of members from a sorted set
      #   redis.zrem("zset", ["a", "b"])
      #
      # @param [String] key
      # @param [String, Array<String>] member
      #   - a single member
      #   - an array of members
      #
      # @return [Boolean, Integer]
      #   - `Boolean` when a single member is specified, holding whether or not it
      #   was removed from the sorted set
      #   - `Integer` when an array of pairs is specified, holding the number of
      #   members that were removed to the sorted set
      def zrem(key, member)
        if member.is_a?(Array)
          members_to_remove = member
          return 0 if members_to_remove.empty?
        end

        send_command([:zrem, key, member]) do |reply|
          if member.is_a? Array
            # Variadic: return integer
            reply
          else
            # Single argument: return boolean
            Boolify.call(reply)
          end
        end
      end

      # Removes and returns up to count members with the highest scores in the sorted set stored at key.
      #
      # @example Popping a member
      #   redis.zpopmax('zset')
      #   #=> ['b', 2.0]
      # @example With count option
      #   redis.zpopmax('zset', 2)
      #   #=> [['b', 2.0], ['a', 1.0]]
      #
      # @params key [String] a key of the sorted set
      # @params count [Integer] a number of members
      #
      # @return [Array<String, Float>] element and score pair if count is not specified
      # @return [Array<Array<String, Float>>] list of popped elements and scores
      def zpopmax(key, count = nil)
        command = [:zpopmax, key]
        command << Integer(count) if count
        send_command(command) do |members|
          members = FloatifyPairs.call(members)
          count.to_i > 1 ? members : members.first
        end
      end

      # Removes and returns up to count members with the lowest scores in the sorted set stored at key.
      #
      # @example Popping a member
      #   redis.zpopmin('zset')
      #   #=> ['a', 1.0]
      # @example With count option
      #   redis.zpopmin('zset', 2)
      #   #=> [['a', 1.0], ['b', 2.0]]
      #
      # @params key [String] a key of the sorted set
      # @params count [Integer] a number of members
      #
      # @return [Array<String, Float>] element and score pair if count is not specified
      # @return [Array<Array<String, Float>>] list of popped elements and scores
      def zpopmin(key, count = nil)
        command = [:zpopmin, key]
        command << Integer(count) if count
        send_command(command) do |members|
          members = FloatifyPairs.call(members)
          count.to_i > 1 ? members : members.first
        end
      end

      # Removes and returns up to count members with the highest scores in the sorted set stored at keys,
      #   or block until one is available.
      #
      # @example Popping a member from a sorted set
      #   redis.bzpopmax('zset', 1)
      #   #=> ['zset', 'b', 2.0]
      # @example Popping a member from multiple sorted sets
      #   redis.bzpopmax('zset1', 'zset2', 1)
      #   #=> ['zset1', 'b', 2.0]
      #
      # @params keys [Array<String>] one or multiple keys of the sorted sets
      # @params timeout [Integer] the maximum number of seconds to block
      #
      # @return [Array<String, String, Float>] a touple of key, member and score
      # @return [nil] when no element could be popped and the timeout expired
      def bzpopmax(*args)
        _bpop(:bzpopmax, args) do |reply|
          reply.is_a?(Array) ? [reply[0], reply[1], Floatify.call(reply[2])] : reply
        end
      end

      # Removes and returns up to count members with the lowest scores in the sorted set stored at keys,
      #   or block until one is available.
      #
      # @example Popping a member from a sorted set
      #   redis.bzpopmin('zset', 1)
      #   #=> ['zset', 'a', 1.0]
      # @example Popping a member from multiple sorted sets
      #   redis.bzpopmin('zset1', 'zset2', 1)
      #   #=> ['zset1', 'a', 1.0]
      #
      # @params keys [Array<String>] one or multiple keys of the sorted sets
      # @params timeout [Integer] the maximum number of seconds to block
      #
      # @return [Array<String, String, Float>] a touple of key, member and score
      # @return [nil] when no element could be popped and the timeout expired
      def bzpopmin(*args)
        _bpop(:bzpopmin, args) do |reply|
          reply.is_a?(Array) ? [reply[0], reply[1], Floatify.call(reply[2])] : reply
        end
      end

      # Get the score associated with the given member in a sorted set.
      #
      # @example Get the score for member "a"
      #   redis.zscore("zset", "a")
      #     # => 32.0
      #
      # @param [String] key
      # @param [String] member
      # @return [Float] score of the member
      def zscore(key, member)
        send_command([:zscore, key, member], &Floatify)
      end

      # Get the scores associated with the given members in a sorted set.
      #
      # @example Get the scores for members "a" and "b"
      #   redis.zmscore("zset", "a", "b")
      #     # => [32.0, 48.0]
      #
      # @param [String] key
      # @param [String, Array<String>] members
      # @return [Array<Float>] scores of the members
      def zmscore(key, *members)
        send_command([:zmscore, key, *members]) do |reply|
          reply.map(&Floatify)
        end
      end

      # Get one or more random members from a sorted set.
      #
      # @example Get one random member
      #   redis.zrandmember("zset")
      #     # => "a"
      # @example Get multiple random members
      #   redis.zrandmember("zset", 2)
      #     # => ["a", "b"]
      # @example Get multiple random members with scores
      #   redis.zrandmember("zset", 2, with_scores: true)
      #     # => [["a", 2.0], ["b", 3.0]]
      #
      # @param [String] key
      # @param [Integer] count
      # @param [Hash] options
      #   - `:with_scores => true`: include scores in output
      #
      # @return [nil, String, Array<String>, Array<[String, Float]>]
      #   - when `key` does not exist or set is empty, `nil`
      #   - when `count` is not specified, a member
      #   - when `count` is specified and `:with_scores` is not specified, an array of members
      #   - when `:with_scores` is specified, an array with `[member, score]` pairs
      def zrandmember(key, count = nil, withscores: false, with_scores: withscores)
        if with_scores && count.nil?
          raise ArgumentError, "count argument must be specified"
        end

        args = [:zrandmember, key]
        args << Integer(count) if count

        if with_scores
          args << "WITHSCORES"
          block = FloatifyPairs
        end

        send_command(args, &block)
      end

      # Return a range of members in a sorted set, by index, score or lexicographical ordering.
      #
      # @example Retrieve all members from a sorted set, by index
      #   redis.zrange("zset", 0, -1)
      #     # => ["a", "b"]
      # @example Retrieve all members and their scores from a sorted set
      #   redis.zrange("zset", 0, -1, :with_scores => true)
      #     # => [["a", 32.0], ["b", 64.0]]
      #
      # @param [String] key
      # @param [Integer] start start index
      # @param [Integer] stop stop index
      # @param [Hash] options
      #   - `:by_score => false`: return members by score
      #   - `:by_lex => false`: return members by lexicographical ordering
      #   - `:rev => false`: reverse the ordering, from highest to lowest
      #   - `:limit => [offset, count]`: skip `offset` members, return a maximum of
      #   `count` members
      #   - `:with_scores => true`: include scores in output
      #
      # @return [Array<String>, Array<[String, Float]>]
      #   - when `:with_scores` is not specified, an array of members
      #   - when `:with_scores` is specified, an array with `[member, score]` pairs
      def zrange(key, start, stop, byscore: false, by_score: byscore, bylex: false, by_lex: bylex,
                 rev: false, limit: nil, withscores: false, with_scores: withscores)

        if by_score && by_lex
          raise ArgumentError, "only one of :by_score or :by_lex can be specified"
        end

        args = [:zrange, key, start, stop]

        if by_score
          args << "BYSCORE"
        elsif by_lex
          args << "BYLEX"
        end

        args << "REV" if rev

        if limit
          args << "LIMIT"
          args.concat(limit.map { |l| Integer(l) })
        end

        if with_scores
          args << "WITHSCORES"
          block = FloatifyPairs
        end

        send_command(args, &block)
      end

      # Select a range of members in a sorted set, by index, score or lexicographical ordering
      # and store the resulting sorted set in a new key.
      #
      # @example
      #   redis.zadd("foo", [[1.0, "s1"], [2.0, "s2"], [3.0, "s3"]])
      #   redis.zrangestore("bar", "foo", 0, 1)
      #     # => 2
      #   redis.zrange("bar", 0, -1)
      #     # => ["s1", "s2"]
      #
      # @return [Integer] the number of elements in the resulting sorted set
      # @see #zrange
      def zrangestore(dest_key, src_key, start, stop, byscore: false, by_score: byscore,
                      bylex: false, by_lex: bylex, rev: false, limit: nil)
        if by_score && by_lex
          raise ArgumentError, "only one of :by_score or :by_lex can be specified"
        end

        args = [:zrangestore, dest_key, src_key, start, stop]

        if by_score
          args << "BYSCORE"
        elsif by_lex
          args << "BYLEX"
        end

        args << "REV" if rev

        if limit
          args << "LIMIT"
          args.concat(limit.map { |l| Integer(l) })
        end

        send_command(args)
      end

      # Return a range of members in a sorted set, by index, with scores ordered
      # from high to low.
      #
      # @example Retrieve all members from a sorted set
      #   redis.zrevrange("zset", 0, -1)
      #     # => ["b", "a"]
      # @example Retrieve all members and their scores from a sorted set
      #   redis.zrevrange("zset", 0, -1, :with_scores => true)
      #     # => [["b", 64.0], ["a", 32.0]]
      #
      # @see #zrange
      def zrevrange(key, start, stop, withscores: false, with_scores: withscores)
        args = [:zrevrange, key, Integer(start), Integer(stop)]

        if with_scores
          args << "WITHSCORES"
          block = FloatifyPairs
        end

        send_command(args, &block)
      end

      # Determine the index of a member in a sorted set.
      #
      # @param [String] key
      # @param [String] member
      # @return [Integer]
      def zrank(key, member)
        send_command([:zrank, key, member])
      end

      # Determine the index of a member in a sorted set, with scores ordered from
      # high to low.
      #
      # @param [String] key
      # @param [String] member
      # @return [Integer]
      def zrevrank(key, member)
        send_command([:zrevrank, key, member])
      end

      # Remove all members in a sorted set within the given indexes.
      #
      # @example Remove first 5 members
      #   redis.zremrangebyrank("zset", 0, 4)
      #     # => 5
      # @example Remove last 5 members
      #   redis.zremrangebyrank("zset", -5, -1)
      #     # => 5
      #
      # @param [String] key
      # @param [Integer] start start index
      # @param [Integer] stop stop index
      # @return [Integer] number of members that were removed
      def zremrangebyrank(key, start, stop)
        send_command([:zremrangebyrank, key, start, stop])
      end

      # Count the members, with the same score in a sorted set, within the given lexicographical range.
      #
      # @example Count members matching a
      #   redis.zlexcount("zset", "[a", "[a\xff")
      #     # => 1
      # @example Count members matching a-z
      #   redis.zlexcount("zset", "[a", "[z\xff")
      #     # => 26
      #
      # @param [String] key
      # @param [String] min
      #   - inclusive minimum is specified by prefixing `(`
      #   - exclusive minimum is specified by prefixing `[`
      # @param [String] max
      #   - inclusive maximum is specified by prefixing `(`
      #   - exclusive maximum is specified by prefixing `[`
      #
      # @return [Integer] number of members within the specified lexicographical range
      def zlexcount(key, min, max)
        send_command([:zlexcount, key, min, max])
      end

      # Return a range of members with the same score in a sorted set, by lexicographical ordering
      #
      # @example Retrieve members matching a
      #   redis.zrangebylex("zset", "[a", "[a\xff")
      #     # => ["aaren", "aarika", "abagael", "abby"]
      # @example Retrieve the first 2 members matching a
      #   redis.zrangebylex("zset", "[a", "[a\xff", :limit => [0, 2])
      #     # => ["aaren", "aarika"]
      #
      # @param [String] key
      # @param [String] min
      #   - inclusive minimum is specified by prefixing `(`
      #   - exclusive minimum is specified by prefixing `[`
      # @param [String] max
      #   - inclusive maximum is specified by prefixing `(`
      #   - exclusive maximum is specified by prefixing `[`
      # @param [Hash] options
      #   - `:limit => [offset, count]`: skip `offset` members, return a maximum of
      #   `count` members
      #
      # @return [Array<String>, Array<[String, Float]>]
      def zrangebylex(key, min, max, limit: nil)
        args = [:zrangebylex, key, min, max]

        if limit
          args << "LIMIT"
          args.concat(limit.map { |l| Integer(l) })
        end

        send_command(args)
      end

      # Return a range of members with the same score in a sorted set, by reversed lexicographical ordering.
      # Apart from the reversed ordering, #zrevrangebylex is similar to #zrangebylex.
      #
      # @example Retrieve members matching a
      #   redis.zrevrangebylex("zset", "[a", "[a\xff")
      #     # => ["abbygail", "abby", "abagael", "aaren"]
      # @example Retrieve the last 2 members matching a
      #   redis.zrevrangebylex("zset", "[a", "[a\xff", :limit => [0, 2])
      #     # => ["abbygail", "abby"]
      #
      # @see #zrangebylex
      def zrevrangebylex(key, max, min, limit: nil)
        args = [:zrevrangebylex, key, max, min]

        if limit
          args << "LIMIT"
          args.concat(limit.map { |l| Integer(l) })
        end

        send_command(args)
      end

      # Return a range of members in a sorted set, by score.
      #
      # @example Retrieve members with score `>= 5` and `< 100`
      #   redis.zrangebyscore("zset", "5", "(100")
      #     # => ["a", "b"]
      # @example Retrieve the first 2 members with score `>= 0`
      #   redis.zrangebyscore("zset", "0", "+inf", :limit => [0, 2])
      #     # => ["a", "b"]
      # @example Retrieve members and their scores with scores `> 5`
      #   redis.zrangebyscore("zset", "(5", "+inf", :with_scores => true)
      #     # => [["a", 32.0], ["b", 64.0]]
      #
      # @param [String] key
      # @param [String] min
      #   - inclusive minimum score is specified verbatim
      #   - exclusive minimum score is specified by prefixing `(`
      # @param [String] max
      #   - inclusive maximum score is specified verbatim
      #   - exclusive maximum score is specified by prefixing `(`
      # @param [Hash] options
      #   - `:with_scores => true`: include scores in output
      #   - `:limit => [offset, count]`: skip `offset` members, return a maximum of
      #   `count` members
      #
      # @return [Array<String>, Array<[String, Float]>]
      #   - when `:with_scores` is not specified, an array of members
      #   - when `:with_scores` is specified, an array with `[member, score]` pairs
      def zrangebyscore(key, min, max, withscores: false, with_scores: withscores, limit: nil)
        args = [:zrangebyscore, key, min, max]

        if with_scores
          args << "WITHSCORES"
          block = FloatifyPairs
        end

        if limit
          args << "LIMIT"
          args.concat(limit.map { |l| Integer(l) })
        end

        send_command(args, &block)
      end

      # Return a range of members in a sorted set, by score, with scores ordered
      # from high to low.
      #
      # @example Retrieve members with score `< 100` and `>= 5`
      #   redis.zrevrangebyscore("zset", "(100", "5")
      #     # => ["b", "a"]
      # @example Retrieve the first 2 members with score `<= 0`
      #   redis.zrevrangebyscore("zset", "0", "-inf", :limit => [0, 2])
      #     # => ["b", "a"]
      # @example Retrieve members and their scores with scores `> 5`
      #   redis.zrevrangebyscore("zset", "+inf", "(5", :with_scores => true)
      #     # => [["b", 64.0], ["a", 32.0]]
      #
      # @see #zrangebyscore
      def zrevrangebyscore(key, max, min, withscores: false, with_scores: withscores, limit: nil)
        args = [:zrevrangebyscore, key, max, min]

        if with_scores
          args << "WITHSCORES"
          block = FloatifyPairs
        end

        if limit
          args << "LIMIT"
          args.concat(limit.map { |l| Integer(l) })
        end

        send_command(args, &block)
      end

      # Remove all members in a sorted set within the given scores.
      #
      # @example Remove members with score `>= 5` and `< 100`
      #   redis.zremrangebyscore("zset", "5", "(100")
      #     # => 2
      # @example Remove members with scores `> 5`
      #   redis.zremrangebyscore("zset", "(5", "+inf")
      #     # => 2
      #
      # @param [String] key
      # @param [String] min
      #   - inclusive minimum score is specified verbatim
      #   - exclusive minimum score is specified by prefixing `(`
      # @param [String] max
      #   - inclusive maximum score is specified verbatim
      #   - exclusive maximum score is specified by prefixing `(`
      # @return [Integer] number of members that were removed
      def zremrangebyscore(key, min, max)
        send_command([:zremrangebyscore, key, min, max])
      end

      # Count the members in a sorted set with scores within the given values.
      #
      # @example Count members with score `>= 5` and `< 100`
      #   redis.zcount("zset", "5", "(100")
      #     # => 2
      # @example Count members with scores `> 5`
      #   redis.zcount("zset", "(5", "+inf")
      #     # => 2
      #
      # @param [String] key
      # @param [String] min
      #   - inclusive minimum score is specified verbatim
      #   - exclusive minimum score is specified by prefixing `(`
      # @param [String] max
      #   - inclusive maximum score is specified verbatim
      #   - exclusive maximum score is specified by prefixing `(`
      # @return [Integer] number of members in within the specified range
      def zcount(key, min, max)
        send_command([:zcount, key, min, max])
      end

      # Return the intersection of multiple sorted sets
      #
      # @example Retrieve the intersection of `2*zsetA` and `1*zsetB`
      #   redis.zinter("zsetA", "zsetB", :weights => [2.0, 1.0])
      #     # => ["v1", "v2"]
      # @example Retrieve the intersection of `2*zsetA` and `1*zsetB`, and their scores
      #   redis.zinter("zsetA", "zsetB", :weights => [2.0, 1.0], :with_scores => true)
      #     # => [["v1", 3.0], ["v2", 6.0]]
      #
      # @param [String, Array<String>] keys one or more keys to intersect
      # @param [Hash] options
      #   - `:weights => [Float, Float, ...]`: weights to associate with source
      #   sorted sets
      #   - `:aggregate => String`: aggregate function to use (sum, min, max, ...)
      #   - `:with_scores => true`: include scores in output
      #
      # @return [Array<String>, Array<[String, Float]>]
      #   - when `:with_scores` is not specified, an array of members
      #   - when `:with_scores` is specified, an array with `[member, score]` pairs
      def zinter(*args)
        _zsets_operation(:zinter, *args)
      end
      ruby2_keywords(:zinter) if respond_to?(:ruby2_keywords, true)

      # Intersect multiple sorted sets and store the resulting sorted set in a new
      # key.
      #
      # @example Compute the intersection of `2*zsetA` with `1*zsetB`, summing their scores
      #   redis.zinterstore("zsetC", ["zsetA", "zsetB"], :weights => [2.0, 1.0], :aggregate => "sum")
      #     # => 4
      #
      # @param [String] destination destination key
      # @param [Array<String>] keys source keys
      # @param [Hash] options
      #   - `:weights => [Array<Float>]`: weights to associate with source
      #   sorted sets
      #   - `:aggregate => String`: aggregate function to use (sum, min, max)
      # @return [Integer] number of elements in the resulting sorted set
      def zinterstore(*args)
        _zsets_operation_store(:zinterstore, *args)
      end
      ruby2_keywords(:zinterstore) if respond_to?(:ruby2_keywords, true)

      # Return the union of multiple sorted sets
      #
      # @example Retrieve the union of `2*zsetA` and `1*zsetB`
      #   redis.zunion("zsetA", "zsetB", :weights => [2.0, 1.0])
      #     # => ["v1", "v2"]
      # @example Retrieve the union of `2*zsetA` and `1*zsetB`, and their scores
      #   redis.zunion("zsetA", "zsetB", :weights => [2.0, 1.0], :with_scores => true)
      #     # => [["v1", 3.0], ["v2", 6.0]]
      #
      # @param [String, Array<String>] keys one or more keys to union
      # @param [Hash] options
      #   - `:weights => [Array<Float>]`: weights to associate with source
      #   sorted sets
      #   - `:aggregate => String`: aggregate function to use (sum, min, max)
      #   - `:with_scores => true`: include scores in output
      #
      # @return [Array<String>, Array<[String, Float]>]
      #   - when `:with_scores` is not specified, an array of members
      #   - when `:with_scores` is specified, an array with `[member, score]` pairs
      def zunion(*args)
        _zsets_operation(:zunion, *args)
      end
      ruby2_keywords(:zunion) if respond_to?(:ruby2_keywords, true)

      # Add multiple sorted sets and store the resulting sorted set in a new key.
      #
      # @example Compute the union of `2*zsetA` with `1*zsetB`, summing their scores
      #   redis.zunionstore("zsetC", ["zsetA", "zsetB"], :weights => [2.0, 1.0], :aggregate => "sum")
      #     # => 8
      #
      # @param [String] destination destination key
      # @param [Array<String>] keys source keys
      # @param [Hash] options
      #   - `:weights => [Float, Float, ...]`: weights to associate with source
      #   sorted sets
      #   - `:aggregate => String`: aggregate function to use (sum, min, max, ...)
      # @return [Integer] number of elements in the resulting sorted set
      def zunionstore(*args)
        _zsets_operation_store(:zunionstore, *args)
      end
      ruby2_keywords(:zunionstore) if respond_to?(:ruby2_keywords, true)

      # Return the difference between the first and all successive input sorted sets
      #
      # @example
      #   redis.zadd("zsetA", [[1.0, "v1"], [2.0, "v2"]])
      #   redis.zadd("zsetB", [[3.0, "v2"], [2.0, "v3"]])
      #   redis.zdiff("zsetA", "zsetB")
      #     => ["v1"]
      # @example With scores
      #   redis.zadd("zsetA", [[1.0, "v1"], [2.0, "v2"]])
      #   redis.zadd("zsetB", [[3.0, "v2"], [2.0, "v3"]])
      #   redis.zdiff("zsetA", "zsetB", :with_scores => true)
      #     => [["v1", 1.0]]
      #
      # @param [String, Array<String>] keys one or more keys to compute the difference
      # @param [Hash] options
      #   - `:with_scores => true`: include scores in output
      #
      # @return [Array<String>, Array<[String, Float]>]
      #   - when `:with_scores` is not specified, an array of members
      #   - when `:with_scores` is specified, an array with `[member, score]` pairs
      def zdiff(*keys, with_scores: false)
        _zsets_operation(:zdiff, *keys, with_scores: with_scores)
      end

      # Compute the difference between the first and all successive input sorted sets
      # and store the resulting sorted set in a new key
      #
      # @example
      #   redis.zadd("zsetA", [[1.0, "v1"], [2.0, "v2"]])
      #   redis.zadd("zsetB", [[3.0, "v2"], [2.0, "v3"]])
      #   redis.zdiffstore("zsetA", "zsetB")
      #     # => 1
      #
      # @param [String] destination destination key
      # @param [Array<String>] keys source keys
      # @return [Integer] number of elements in the resulting sorted set
      def zdiffstore(*args)
        _zsets_operation_store(:zdiffstore, *args)
      end
      ruby2_keywords(:zdiffstore) if respond_to?(:ruby2_keywords, true)

      # Scan a sorted set
      #
      # @example Retrieve the first batch of key/value pairs in a hash
      #   redis.zscan("zset", 0)
      #
      # @param [String, Integer] cursor the cursor of the iteration
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #
      # @return [String, Array<[String, Float]>] the next cursor and all found
      #   members and scores
      def zscan(key, cursor, **options)
        _scan(:zscan, cursor, [key], **options) do |reply|
          [reply[0], FloatifyPairs.call(reply[1])]
        end
      end

      # Scan a sorted set
      #
      # @example Retrieve all of the members/scores in a sorted set
      #   redis.zscan_each("zset").to_a
      #   # => [["key70", "70"], ["key80", "80"]]
      #
      # @param [Hash] options
      #   - `:match => String`: only return keys matching the pattern
      #   - `:count => Integer`: return count keys at most per iteration
      #
      # @return [Enumerator] an enumerator for all found scores and members
      def zscan_each(key, **options, &block)
        return to_enum(:zscan_each, key, **options) unless block_given?

        cursor = 0
        loop do
          cursor, values = zscan(key, cursor, **options)
          values.each(&block)
          break if cursor == "0"
        end
      end

      private

      def _zsets_operation(cmd, *keys, weights: nil, aggregate: nil, with_scores: false)
        keys.flatten!(1)
        command = [cmd, keys.size].concat(keys)

        if weights
          command << "WEIGHTS"
          command.concat(weights)
        end

        command << "AGGREGATE" << aggregate if aggregate

        if with_scores
          command << "WITHSCORES"
          block = FloatifyPairs
        end

        send_command(command, &block)
      end

      def _zsets_operation_store(cmd, destination, keys, weights: nil, aggregate: nil)
        keys.flatten!(1)
        command = [cmd, destination, keys.size].concat(keys)

        if weights
          command << "WEIGHTS"
          command.concat(weights)
        end

        command << "AGGREGATE" << aggregate if aggregate

        send_command(command)
      end
    end
  end
end
