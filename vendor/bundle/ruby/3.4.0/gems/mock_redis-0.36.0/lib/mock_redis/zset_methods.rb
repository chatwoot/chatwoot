require 'mock_redis/assertions'
require 'mock_redis/utility_methods'
require 'mock_redis/zset'

class MockRedis
  module ZsetMethods
    include Assertions
    include UtilityMethods

    def zadd(key, *args)
      zadd_options = {}
      zadd_options = args.pop if args.last.is_a?(Hash)

      if zadd_options&.include?(:nx) && zadd_options&.include?(:xx)
        raise Redis::CommandError, 'ERR XX and NX options at the same time are not compatible'
      end

      if args.size == 1 && args[0].is_a?(Array)
        zadd_multiple_members(key, args.first, zadd_options)
      elsif args.size == 2
        score, member = args
        zadd_one_member(key, score, member, zadd_options)
      else
        raise Redis::CommandError, 'ERR wrong number of arguments'
      end
    end

    def zadd_one_member(key, score, member, zadd_options = {})
      assert_scorey(score) unless score.to_s =~ /(\+|\-)inf/

      with_zset_at(key) do |zset|
        if zadd_options[:incr]
          if zadd_options[:xx]
            member_present = zset.include?(member)
            return member_present ? zincrby(key, score, member) : nil
          end

          if zadd_options[:nx]
            member_present = zset.include?(member)
            return member_present ? nil : zincrby(key, score, member)
          end

          zincrby(key, score, member)
        elsif zadd_options[:xx]
          zset.add(score, member.to_s) if zset.include?(member)
          false
        elsif zadd_options[:nx]
          !zset.include?(member) && !!zset.add(score, member.to_s)
        else
          retval = !zscore(key, member)
          zset.add(score, member.to_s)
          retval
        end
      end
    end

    private :zadd_one_member

    def zadd_multiple_members(key, args, zadd_options = {})
      assert_has_args(args, 'zadd')

      args = args.each_slice(2).to_a unless args.first.is_a?(Array)
      with_zset_at(key) do |zset|
        if zadd_options[:incr]
          raise Redis::CommandError, 'ERR INCR option supports a single increment-element pair'
        elsif zadd_options[:xx]
          args.each { |score, member| zset.include?(member) && zset.add(score, member.to_s) }
          0
        elsif zadd_options[:nx]
          args.reduce(0) do |retval, (score, member)|
            unless zset.include?(member)
              zset.add(score, member.to_s)
              retval += 1
            end
            retval
          end
        else
          args.reduce(0) do |retval, (score, member)|
            retval += 1 unless zset.include?(member)
            zset.add(score, member.to_s)
            retval
          end
        end
      end
    end

    private :zadd_multiple_members

    def zcard(key)
      with_zset_at(key, &:size)
    end

    def zcount(key, min, max)
      assert_range_args(min, max)

      with_zset_at(key) do |zset|
        zset.in_range(min, max).size
      end
    end

    def zincrby(key, increment, member)
      assert_scorey(increment)
      member = member.to_s
      with_zset_at(key) do |z|
        old_score = z.include?(member) ? z.score(member) : 0
        new_score = old_score + increment
        z.add(new_score, member)
        new_score.to_f
      end
    end

    def zinterstore(destination, keys, options = {})
      assert_has_args(keys, 'zinterstore')

      data[destination] = combine_weighted_zsets(keys, options, :intersection)
      zcard(destination)
    end

    def zrange(key, start, stop, options = {})
      with_zset_at(key) do |z|
        start = [start.to_i, -z.sorted.size].max
        stop = stop.to_i
        to_response(z.sorted[start..stop] || [], options)
      end
    end

    def zrangebyscore(key, min, max, options = {})
      assert_range_args(min, max)

      with_zset_at(key) do |zset|
        all_results = zset.in_range(min, max)
        to_response(apply_limit(all_results, options[:limit]), options)
      end
    end

    def zrank(key, member)
      with_zset_at(key) { |z| z.sorted_members.index(member.to_s) }
    end

    def zrem(key, *args)
      if !args.first.is_a?(Array)
        retval = with_zset_at(key) { |z| !!z.delete?(args.first.to_s) }
      else
        args = args.first
        if args.empty?
          raise Redis::CommandError, "ERR wrong number of arguments for 'zrem' command"
        else
          retval = args.map { |member| !!zscore(key, member.to_s) }.count(true)
          with_zset_at(key) do |z|
            args.each { |member| z.delete?(member.to_s) }
          end
        end
      end

      retval
    end

    def zpopmin(key, count = 1)
      with_zset_at(key) do |z|
        pairs = z.sorted.first(count)
        pairs.each { |pair| z.delete?(pair.last) }
        retval = to_response(pairs, with_scores: true)
        count == 1 ? retval.first : retval
      end
    end

    def zpopmax(key, count = 1)
      with_zset_at(key) do |z|
        pairs = z.sorted.reverse.first(count)
        pairs.each { |pair| z.delete?(pair.last) }
        retval = to_response(pairs, with_scores: true)
        count == 1 ? retval.first : retval
      end
    end

    def zrevrange(key, start, stop, options = {})
      with_zset_at(key) do |z|
        to_response(z.sorted.reverse[start..stop] || [], options)
      end
    end

    def zremrangebyrank(key, start, stop)
      zrange(key, start, stop).
        each { |member| zrem(key, member) }.
        size
    end

    def zremrangebyscore(key, min, max)
      assert_range_args(min, max)

      zrangebyscore(key, min, max).
        each { |member| zrem(key, member) }.
        size
    end

    def zrevrangebyscore(key, max, min, options = {})
      assert_range_args(min, max)

      with_zset_at(key) do |zset|
        to_response(
          apply_limit(
            zset.in_range(min, max).reverse,
            options[:limit]
          ),
          options
        )
      end
    end

    def zrevrank(key, member)
      with_zset_at(key) { |z| z.sorted_members.reverse.index(member.to_s) }
    end

    def zscan(key, cursor, opts = {})
      opts = opts.merge(key: lambda { |x| x[0] })
      common_scan(zrange(key, 0, -1, withscores: true), cursor, opts)
    end

    def zscan_each(key, opts = {}, &block)
      return to_enum(:zscan_each, key, opts) unless block_given?
      cursor = 0
      loop do
        cursor, values = zscan(key, cursor, opts)
        values.each(&block)
        break if cursor == '0'
      end
    end

    def zscore(key, member)
      with_zset_at(key) do |z|
        score = z.score(member.to_s)
        score&.to_f
      end
    end

    def zunionstore(destination, keys, options = {})
      assert_has_args(keys, 'zunionstore')

      data[destination] = combine_weighted_zsets(keys, options, :union)
      zcard(destination)
    end

    private

    def apply_limit(collection, limit)
      if limit
        if limit.is_a?(Array) && limit.length == 2
          offset, count = limit
          collection.drop(offset).take(count)
        else
          raise Redis::CommandError, 'ERR syntax error'
        end
      else
        collection
      end
    end

    def to_response(score_member_pairs, options)
      score_member_pairs.map do |(score, member)|
        if options[:with_scores] || options[:withscores]
          [member, score.to_f]
        else
          member
        end
      end
    end

    def combine_weighted_zsets(keys, options, how)
      weights = options.fetch(:weights, keys.map { 1 })
      if weights.length != keys.length
        raise Redis::CommandError, 'ERR syntax error'
      end

      aggregator = case options.fetch(:aggregate, :sum).to_s.downcase.to_sym
                   when :sum
                     proc { |a, b| [a, b].compact.reduce(&:+) }
                   when :min
                     proc { |a, b| [a, b].compact.min }
                   when :max
                     proc { |a, b| [a, b].compact.max }
                   else
                     raise Redis::CommandError, 'ERR syntax error'
                   end

      with_zsets_at(*keys, coercible: true) do |*zsets|
        zsets.zip(weights).map do |(zset, weight)|
          zset.reduce(Zset.new) do |acc, (score, member)|
            acc.add(score * weight, member)
          end
        end.reduce do |za, zb|
          za.send(how, zb, &aggregator)
        end
      end
    end

    def coerce_to_zset(set)
      zset = Zset.new
      set.each do |member|
        zset.add(1.0, member)
      end
      zset
    end

    def with_zset_at(key, coercible: false, &blk)
      if coercible
        with_thing_at(key, :assert_coercible_zsety, proc { Zset.new }) do |value|
          blk.call value.is_a?(Set) ? coerce_to_zset(value) : value
        end
      else
        with_thing_at(key, :assert_zsety, proc { Zset.new }, &blk)
      end
    end

    def with_zsets_at(*keys, coercible: false, &blk)
      if keys.length == 1
        with_zset_at(keys.first, coercible: coercible, &blk)
      else
        with_zset_at(keys.first, coercible: coercible) do |set|
          with_zsets_at(*(keys[1..-1]), coercible: coercible) do |*sets|
            yield(*([set] + sets))
          end
        end
      end
    end

    def zsety?(key)
      data[key].nil? || data[key].is_a?(Zset)
    end

    def coercible_zsety?(key)
      zsety?(key) || data[key].is_a?(Set)
    end

    def assert_zsety(key)
      unless zsety?(key)
        raise Redis::CommandError,
          'WRONGTYPE Operation against a key holding the wrong kind of value'
      end
    end

    def assert_coercible_zsety(key)
      unless coercible_zsety?(key)
        raise Redis::CommandError,
          'WRONGTYPE Operation against a key holding the wrong kind of value'
      end
    end

    def looks_like_float?(x)
      # ugh, exceptions for flow control.
      !!Float(x) rescue false
    end

    def assert_scorey(value, message = 'ERR value is not a valid float')
      return if value.to_s =~ /\(?(\-|\+)inf/

      value = $1 if value.to_s =~ /\((.*)/
      unless looks_like_float?(value)
        raise Redis::CommandError, message
      end
    end

    def assert_range_args(min, max)
      [min, max].each do |value|
        assert_scorey(value, 'ERR min or max is not a float')
      end
    end
  end
end
