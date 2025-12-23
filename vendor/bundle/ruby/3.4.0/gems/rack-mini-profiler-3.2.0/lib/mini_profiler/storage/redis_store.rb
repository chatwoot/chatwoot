# frozen_string_literal: true

require 'digest'
require 'securerandom'

module Rack
  class MiniProfiler
    class RedisStore < AbstractStore

      attr_reader :prefix

      EXPIRES_IN_SECONDS = 60 * 60 * 24

      def initialize(args = nil)
        @args               = args || {}
        @prefix             = @args.delete(:prefix) || 'MPRedisStore'
        @redis_connection   = @args.delete(:connection)
        @expires_in_seconds = @args.delete(:expires_in) || EXPIRES_IN_SECONDS
      end

      def save(page_struct)
        redis.setex prefixed_id(page_struct[:id]), @expires_in_seconds, Marshal::dump(page_struct)
      end

      def load(id)
        key = prefixed_id(id)
        raw = redis.get key
        begin
          # rubocop:disable Security/MarshalLoad
          Marshal.load(raw) if raw
          # rubocop:enable Security/MarshalLoad
        rescue
          # bad format, junk old data
          redis.del key
          nil
        end
      end

      def set_unviewed(user, id)
        key = user_key(user)
        if redis.call([:exists, prefixed_id(id)]) == 1
          expire_at = Process.clock_gettime(Process::CLOCK_MONOTONIC).to_i + redis.ttl(prefixed_id(id))
          redis.zadd(key, expire_at, id)
        end
        redis.expire(key, @expires_in_seconds)
      end

      def set_all_unviewed(user, ids)
        key = user_key(user)
        redis.del(key)
        ids.each do |id|
          if redis.call([:exists, prefixed_id(id)]) == 1
            expire_at = Process.clock_gettime(Process::CLOCK_MONOTONIC).to_i + redis.ttl(prefixed_id(id))
            redis.zadd(key, expire_at, id)
          end
        end
        redis.expire(key, @expires_in_seconds)
      end

      def set_viewed(user, id)
        redis.zrem(user_key(user), id)
      end

      # Remove expired ids from the unviewed sorted set and return the remaining ids
      def get_unviewed_ids(user)
        key = user_key(user)
        redis.zremrangebyscore(key, '-inf', Process.clock_gettime(Process::CLOCK_MONOTONIC).to_i)
        redis.zrevrangebyscore(key, '+inf', '-inf')
      end

      def diagnostics(user)
        client = (redis.respond_to? :_client) ? redis._client : redis.client
"Redis prefix: #{@prefix}
Redis location: #{client.host}:#{client.port} db: #{client.db}
unviewed_ids: #{get_unviewed_ids(user)}
"
      end

      def flush_tokens
        redis.del("#{@prefix}-key1", "#{@prefix}-key1_old", "#{@prefix}-key2")
      end

      # Only used for testing
      def simulate_expire
        redis.del("#{@prefix}-key1")
      end

      def allowed_tokens
        key1, key1_old, key2 = redis.mget("#{@prefix}-key1", "#{@prefix}-key1_old", "#{@prefix}-key2")

        if key1 && (key1.length == 32)
          return [key1, key2].compact
        end

        timeout = Rack::MiniProfiler::AbstractStore::MAX_TOKEN_AGE

        # TODO  this could be moved to lua to correct a concurrency flaw
        # it is not critical cause worse case some requests will miss profiling info

        # no key so go ahead and set it
        key1 = SecureRandom.hex

        if key1_old && (key1_old.length == 32)
          key2 = key1_old
          redis.setex "#{@prefix}-key2", timeout, key2
        else
          key2 = nil
        end

        redis.setex "#{@prefix}-key1", timeout, key1
        redis.setex "#{@prefix}-key1_old", timeout * 2, key1

        [key1, key2].compact
      end

      COUNTER_LUA = <<~LUA
        if redis.call("INCR", KEYS[1]) % ARGV[1] == 0 then
          redis.call("DEL", KEYS[1])
          return 1
        else
          return 0
        end
      LUA

      COUNTER_LUA_SHA = Digest::SHA1.hexdigest(COUNTER_LUA)

      def should_take_snapshot?(period)
        1 == cached_redis_eval(
          COUNTER_LUA,
          COUNTER_LUA_SHA,
          reraise: false,
          keys: [snapshot_counter_key()],
          argv: [period]
        )
      end

      def push_snapshot(page_struct, group_name, config)
        group_zset_key = group_snapshot_zset_key(group_name)
        group_hash_key = group_snapshot_hash_key(group_name)
        overview_zset_key = snapshot_overview_zset_key

        id = page_struct[:id]
        score = page_struct.duration_ms.to_s

        per_group_limit = config.max_snapshots_per_group.to_s
        groups_limit = config.max_snapshot_groups.to_s
        bytes = Marshal.dump(page_struct)

        lua = <<~LUA
          local group_zset_key = KEYS[1]
          local group_hash_key = KEYS[2]
          local overview_zset_key = KEYS[3]

          local id = ARGV[1]
          local score = tonumber(ARGV[2])
          local group_name = ARGV[3]
          local per_group_limit = tonumber(ARGV[4])
          local groups_limit = tonumber(ARGV[5])
          local prefix = ARGV[6]
          local bytes = ARGV[7]

          local current_group_score = redis.call("ZSCORE", overview_zset_key, group_name)
          if current_group_score == false or score > tonumber(current_group_score) then
            redis.call("ZADD", overview_zset_key, score, group_name)
          end

          local do_save = true
          local overview_size = redis.call("ZCARD", overview_zset_key)
          while (overview_size > groups_limit) do
            local lowest_group = redis.call("ZRANGE", overview_zset_key, 0, 0)[1]
            redis.call("ZREM", overview_zset_key, lowest_group)
            if lowest_group == group_name then
              do_save = false
            else
              local lowest_group_zset_key = prefix .. "-mp-group-snapshot-zset-key-" .. lowest_group
              local lowest_group_hash_key = prefix .. "-mp-group-snapshot-hash-key-" .. lowest_group
              redis.call("DEL", lowest_group_zset_key, lowest_group_hash_key)
            end
            overview_size = overview_size - 1
          end

          if do_save then
            redis.call("ZADD", group_zset_key, score, id)
            local group_size = redis.call("ZCARD", group_zset_key)
            while (group_size > per_group_limit) do
              local lowest_snapshot_id = redis.call("ZRANGE", group_zset_key, 0, 0)[1]
              redis.call("ZREM", group_zset_key, lowest_snapshot_id)
              if lowest_snapshot_id == id then
                do_save = false
              else
                redis.call("HDEL", group_hash_key, lowest_snapshot_id)
              end
              group_size = group_size - 1
            end
            if do_save then
              redis.call("HSET", group_hash_key, id, bytes)
            end
          end
        LUA
        redis.eval(
          lua,
          keys: [group_zset_key, group_hash_key, overview_zset_key],
          argv: [id, score, group_name, per_group_limit, groups_limit, @prefix, bytes]
        )
      end

      def fetch_snapshots_overview
        overview_zset_key = snapshot_overview_zset_key
        groups = redis
          .zrange(overview_zset_key, 0, -1, withscores: true)
          .map { |(name, worst_score)| [name, { worst_score: worst_score }] }

        prefixed_group_names = groups.map { |(group_name, _)| group_snapshot_zset_key(group_name) }
        metadata = redis.eval(<<~LUA, keys: prefixed_group_names)
          local metadata = {}
          for i, k in ipairs(KEYS) do
            local best = redis.call("ZRANGE", k, 0, 0, "WITHSCORES")[2]
            local count = redis.call("ZCARD", k)
            metadata[i] = {best, count}
          end
          return metadata
        LUA
        groups.each.with_index do |(_, hash), index|
          best, count = metadata[index]
          hash[:best_score] = best.to_f
          hash[:snapshots_count] = count.to_i
        end
        groups.to_h
      end

      def fetch_snapshots_group(group_name)
        group_hash_key = group_snapshot_hash_key(group_name)
        snapshots = []
        corrupt_snapshots = []
        redis.hgetall(group_hash_key).each do |id, bytes|
          # rubocop:disable Security/MarshalLoad
          snapshots << Marshal.load(bytes)
          # rubocop:enable Security/MarshalLoad
        rescue
          corrupt_snapshots << id
        end
        if corrupt_snapshots.size > 0
          cleanup_corrupt_snapshots(corrupt_snapshots, group_name)
        end
        snapshots
      end

      def load_snapshot(id, group_name)
        group_hash_key = group_snapshot_hash_key(group_name)
        bytes = redis.hget(group_hash_key, id)
        return if !bytes
        begin
          # rubocop:disable Security/MarshalLoad
          Marshal.load(bytes)
          # rubocop:enable Security/MarshalLoad
        rescue
          cleanup_corrupt_snapshots([id], group_name)
          nil
        end
      end

      private

      def user_key(user)
        "#{@prefix}-#{user}-v1"
      end

      def prefixed_id(id)
        "#{@prefix}#{id}"
      end

      def redis
        @redis_connection ||= begin
          require 'redis' unless defined? Redis
          Redis.new(@args)
        end
      end

      def snapshot_counter_key
        @snapshot_counter_key ||= "#{@prefix}-mini-profiler-snapshots-counter"
      end

      def group_snapshot_zset_key(group_name)
        # if you change this key, remember to change it in the LUA script in
        # the push_snapshot method as well
        "#{@prefix}-mp-group-snapshot-zset-key-#{group_name}"
      end

      def group_snapshot_hash_key(group_name)
        # if you change this key, remember to change it in the LUA script in
        # the push_snapshot method as well
        "#{@prefix}-mp-group-snapshot-hash-key-#{group_name}"
      end

      def snapshot_overview_zset_key
        "#{@prefix}-mp-overviewgroup-snapshot-zset-key"
      end

      def cached_redis_eval(script, script_sha, reraise: true, argv: [], keys: [])
        begin
          redis.evalsha(script_sha, argv: argv, keys: keys)
        rescue ::Redis::CommandError => e
          if e.message.start_with?('NOSCRIPT')
            redis.eval(script, argv: argv, keys: keys)
          else
            raise e if reraise
          end
        end
      end

      def cleanup_corrupt_snapshots(corrupt_snapshots_ids, group_name)
        group_hash_key = group_snapshot_hash_key(group_name)
        group_zset_key = group_snapshot_zset_key(group_name)
        overview_zset_key = snapshot_overview_zset_key
        lua = <<~LUA
          local group_hash_key = KEYS[1]
          local group_zset_key = KEYS[2]
          local overview_zset_key = KEYS[3]
          local group_name = ARGV[1]
          for i, k in ipairs(ARGV) do
            if k ~= group_name then
              redis.call("HDEL", group_hash_key, k)
              redis.call("ZREM", group_zset_key, k)
            end
          end
          if redis.call("ZCARD", group_zset_key) == 0 then
            redis.call("ZREM", overview_zset_key, group_name)
            redis.call("DEL", group_hash_key, group_zset_key)
          else
            local worst_score = tonumber(redis.call("ZRANGE", group_zset_key, -1, -1, "WITHSCORES")[2])
            redis.call("ZADD", overview_zset_key, worst_score, group_name)
          end
        LUA
        redis.eval(
          lua,
          keys: [group_hash_key, group_zset_key, overview_zset_key],
          argv: [group_name, *corrupt_snapshots_ids]
        )
      end

      # only used in tests
      def wipe_snapshots_data
        keys = redis.keys(group_snapshot_hash_key('*'))
        keys += redis.keys(group_snapshot_zset_key('*'))
        redis.del(
          keys,
          snapshot_overview_zset_key,
          snapshot_counter_key
        )
      end
    end
  end
end
