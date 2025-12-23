require 'forwardable'
require 'set'
require 'date'
require 'mock_redis/stream/id'

class MockRedis
  class Stream
    include Enumerable
    extend Forwardable

    attr_accessor :members

    def_delegators :members, :empty?

    def initialize
      @members = Set.new
      @last_id = nil
    end

    def last_id
      @last_id.to_s
    end

    def add(id, values)
      @last_id = MockRedis::Stream::Id.new(id, min: @last_id)
      if @last_id.to_s == '0-0'
        raise Redis::CommandError,
          'ERR The ID specified in XADD must be greater than 0-0'
      end
      members.add [@last_id, Hash[values.map { |k, v| [k.to_s, v.to_s] }]]
      @last_id.to_s
    end

    def trim(count)
      deleted = @members.size - count
      if deleted > 0
        @members = if count == 0
                     Set.new
                   else
                     @members.to_a[-count..-1].to_set
                   end
        deleted
      else
        0
      end
    end

    def range(start, finish, reversed, *opts_in)
      opts = options opts_in, ['count']
      start_id = MockRedis::Stream::Id.new(start)
      finish_id = MockRedis::Stream::Id.new(finish, sequence: Float::INFINITY)
      items = if start_id.exclusive
                members
                  .select { |m| (start_id < m[0]) && (finish_id >= m[0]) }
                  .map { |m| [m[0].to_s, m[1]] }
              else
                members
                  .select { |m| (start_id <= m[0]) && (finish_id >= m[0]) }
                  .map { |m| [m[0].to_s, m[1]] }
              end
      items.reverse! if reversed
      return items.first(opts['count'].to_i) if opts.key?('count')
      items
    end

    def read(id, *opts_in)
      opts = options opts_in, %w[count block]
      stream_id = MockRedis::Stream::Id.new(id)
      items = members.select { |m| (stream_id < m[0]) }.map { |m| [m[0].to_s, m[1]] }
      return items.first(opts['count'].to_i) if opts.key?('count')
      items
    end

    def each
      members.each { |m| yield m }
    end

    private

    def options(opts_in, permitted)
      opts_out = {}
      raise Redis::CommandError, 'ERR syntax error' unless (opts_in.length % 2).zero?
      opts_in.each_slice(2).map { |pair| opts_out[pair[0].downcase] = pair[1] }
      raise Redis::CommandError, 'ERR syntax error' unless (opts_out.keys - permitted).empty?
      opts_out
    end
  end
end
