class MockRedis
  class Stream
    class Id
      include Comparable

      attr_accessor :timestamp, :sequence, :exclusive

      def initialize(id, min: nil, sequence: 0)
        @exclusive = false
        case id
        when '*'
          @timestamp = (Time.now.to_f * 1000).to_i
          @sequence = 0
          if self <= min
            @timestamp = min.timestamp
            @sequence = min.sequence + 1
          end
        when '-'
          @timestamp = @sequence = 0
        when '+'
          @timestamp = @sequence = Float::INFINITY
        else
          if id.is_a? String
            # See https://redis.io/topics/streams-intro
            # Ids are a unix timestamp in milliseconds followed by an
            # optional dash sequence number, e.g. -0. They can also optionally
            # be prefixed with '(' to change the XRANGE to exclusive.
            (_, @timestamp, @sequence) = id.match(/^\(?(\d+)-?(\d+)?$/).to_a
            @exclusive = true if id[0] == '('
            if @timestamp.nil?
              raise Redis::CommandError,
                    'ERR Invalid stream ID specified as stream command argument'
            end
            @timestamp = @timestamp.to_i
          else
            @timestamp = id
          end
          @sequence = @sequence.nil? ? sequence : @sequence.to_i
          if self <= min
            raise Redis::CommandError,
                  'ERR The ID specified in XADD is equal or smaller than ' \
                  'the target stream top item'
          end
        end
      end

      def to_s
        "#{@timestamp}-#{@sequence}"
      end

      def <=>(other)
        return 1 if other.nil?
        return @sequence <=> other.sequence if @timestamp == other.timestamp
        @timestamp <=> other.timestamp
      end
    end
  end
end
