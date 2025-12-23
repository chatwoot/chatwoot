require 'mock_redis/assertions'
require 'mock_redis/utility_methods'

class MockRedis
  module SetMethods
    include Assertions
    include UtilityMethods

    def sadd(key, members)
      members_class = members.class
      members = [members].flatten.map(&:to_s)
      assert_has_args(members, 'sadd')

      with_set_at(key) do |s|
        size_before = s.size
        if members.size > 1
          members.reverse_each { |m| s << m }
          s.size - size_before
        else
          added = !!s.add?(members.first)
          if members_class == Array
            s.size - size_before
          else
            added
          end
        end
      end
    end

    def scard(key)
      with_set_at(key, &:length)
    end

    def sdiff(*keys)
      assert_has_args(keys, 'sdiff')
      with_sets_at(*keys) { |*sets| sets.reduce(&:-) }.to_a
    end

    def sdiffstore(destination, *keys)
      assert_has_args(keys, 'sdiffstore')
      with_set_at(destination) do |set|
        set.replace(sdiff(*keys))
      end
      scard(destination)
    end

    def sinter(*keys)
      assert_has_args(keys, 'sinter')

      with_sets_at(*keys) do |*sets|
        sets.reduce(&:&).to_a
      end
    end

    def sinterstore(destination, *keys)
      assert_has_args(keys, 'sinterstore')
      with_set_at(destination) do |set|
        set.replace(sinter(*keys))
      end
      scard(destination)
    end

    def sismember(key, member)
      with_set_at(key) { |s| s.include?(member.to_s) }
    end

    def smismember(key, *members)
      with_set_at(key) do |set|
        members.flatten.map { |m| set.include?(m.to_s) }
      end
    end

    def smembers(key)
      with_set_at(key, &:to_a).map(&:dup).reverse
    end

    def smove(src, dest, member)
      member = member.to_s

      with_sets_at(src, dest) do |src_set, dest_set|
        if src_set.delete?(member)
          dest_set.add(member)
          true
        else
          false
        end
      end
    end

    def spop(key, count = nil)
      with_set_at(key) do |set|
        if count.nil?
          member = set.first
          set.delete(member)
          member
        else
          members = []
          count.times do
            member = set.first
            break if member.nil?
            set.delete(member)
            members << member
          end
          members
        end
      end
    end

    def srandmember(key, count = nil)
      members = with_set_at(key, &:to_a)
      if count
        if count > 0
          members.sample(count)
        else
          Array.new(count.abs) { members[rand(members.length)] }
        end
      else
        members[rand(members.length)]
      end
    end

    def srem(key, members)
      with_set_at(key) do |s|
        if members.is_a?(Array)
          orig_size = s.size
          members = members.map(&:to_s)
          s.delete_if { |m| members.include?(m) }
          orig_size - s.size
        else
          !!s.delete?(members.to_s)
        end
      end
    end

    def sscan(key, cursor, opts = {})
      common_scan(smembers(key), cursor, opts)
    end

    def sscan_each(key, opts = {}, &block)
      return to_enum(:sscan_each, key, opts) unless block_given?
      cursor = 0
      loop do
        cursor, keys = sscan(key, cursor, opts)
        keys.each(&block)
        break if cursor == '0'
      end
    end

    def sunion(*keys)
      assert_has_args(keys, 'sunion')
      with_sets_at(*keys) { |*sets| sets.reduce(&:+).to_a }
    end

    def sunionstore(destination, *keys)
      assert_has_args(keys, 'sunionstore')
      with_set_at(destination) do |dest_set|
        dest_set.replace(sunion(*keys))
      end
      scard(destination)
    end

    private

    def with_set_at(key, &blk)
      with_thing_at(key, :assert_sety, proc { Set.new }, &blk)
    end

    def with_sets_at(*keys, &blk)
      keys = keys.flatten
      if keys.length == 1
        with_set_at(keys.first, &blk)
      else
        with_set_at(keys.first) do |set|
          with_sets_at(*(keys[1..-1])) do |*sets|
            yield(*([set] + sets))
          end
        end
      end
    end

    def sety?(key)
      data[key].nil? || data[key].is_a?(Set)
    end

    def assert_sety(key)
      unless sety?(key)
        # Not the most helpful error, but it's what redis-rb barfs up
        raise Redis::CommandError,
              'WRONGTYPE Operation against a key holding the wrong kind of value'
      end
    end
  end
end
