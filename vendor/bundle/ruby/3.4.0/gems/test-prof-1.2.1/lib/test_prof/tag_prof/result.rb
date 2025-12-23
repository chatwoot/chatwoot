# frozen_string_literal: true

module TestProf
  module TagProf # :nodoc:
    # Object holding all the stats for tags
    class Result
      attr_reader :tag, :data, :events

      def initialize(tag, events = [])
        @tag = tag
        @events = events

        @data = Hash.new do |h, k|
          h[k] = {value: k, count: 0, time: 0.0}
          h[k].merge!(events.map { |event| [event, 0.0] }.to_h) unless
            events.empty?
          h[k]
        end
      end

      def track(tag, time:, events: {})
        data[tag][:count] += 1
        data[tag][:time] += time
        events.each do |k, v|
          data[tag][k] += v
        end
      end

      def to_json(*args)
        {
          tag: tag,
          data: data.values,
          events: events
        }.to_json(*args)
      end
    end
  end
end
