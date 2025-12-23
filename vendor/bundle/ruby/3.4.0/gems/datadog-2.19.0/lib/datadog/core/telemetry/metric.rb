# frozen_string_literal: true

module Datadog
  module Core
    module Telemetry
      # Telemetry metrics data model (internal Datadog metrics for client libraries)
      module Metric
        # Base class for all metric types
        class Base
          attr_reader :name, :tags, :values, :common

          # @param name [String] metric name
          # @param tags [Array<String>|Hash{String=>String}] metric tags as hash or array of "tag:val" strings
          # @param common [Boolean] true if the metric is common for all languages, false for Ruby-specific metric
          def initialize(name, tags: {}, common: true)
            @name = name
            @values = []
            @tags = tags_to_array(tags)
            @common = common
          end

          def id
            @id ||= "#{type}::#{name}::#{tags.join(",")}"
          end

          def track(value)
            raise NotImplementedError, 'method must be implemented in subclasses'
          end

          def type
            raise NotImplementedError, 'method must be implemented in subclasses'
          end

          def to_h
            {
              metric: name,
              points: values,
              type: type,
              tags: tags,
              common: common
            }
          end

          def ==(other)
            other.is_a?(self.class) &&
              name == other.name &&
              values == other.values && tags == other.tags && common == other.common && type == other.type
          end

          alias_method :eql?, :==

          def hash
            [self.class, name, values, tags, common, type].hash
          end

          private

          def tags_to_array(tags)
            return tags if tags.is_a?(Array)

            tags.map { |k, v| "#{k}:#{v}" }
          end
        end

        # Base class for metrics that require aggregation interval
        class IntervalMetric < Base
          attr_reader :interval

          # @param name [String] metric name
          # @param tags [Array<String>|Hash{String=>String}] metric tags as hash of array of "tag:val" strings
          # @param common [Boolean] true if the metric is common for all languages, false for Ruby-specific metric
          # @param interval [Integer] metrics aggregation interval in seconds
          def initialize(name, interval:, tags: {}, common: true)
            raise ArgumentError, 'interval must be a positive number' if interval.nil? || interval <= 0

            super(name, tags: tags, common: common)

            @interval = interval
          end

          def to_h
            res = super
            res[:interval] = interval
            res
          end

          def ==(other)
            super && interval == other.interval
          end

          alias_method :eql?, :==

          def hash
            [super, interval].hash
          end
        end

        # Count metric adds up all the submitted values in a time interval. This would be suitable for a
        # metric tracking the number of website hits, for instance.
        class Count < Base
          TYPE = 'count'

          def type
            TYPE
          end

          def track(value)
            value = value.to_i

            if values.empty?
              values << [Core::Utils::Time.now.to_i, value]
            else
              values[0][0] = Core::Utils::Time.now.to_i
              values[0][1] += value
            end
            nil
          end
        end

        # A gauge type takes the last value reported during the interval. This type would make sense for tracking RAM or
        # CPU usage, where taking the last value provides a representative picture of the host’s behavior during the time
        # interval.
        class Gauge < IntervalMetric
          TYPE = 'gauge'

          def type
            TYPE
          end

          def track(value)
            if values.empty?
              values << [Core::Utils::Time.now.to_i, value]
            else
              values[0][0] = Core::Utils::Time.now.to_i
              values[0][1] = value
            end
            nil
          end
        end

        # The rate type takes the count and divides it by the length of the time interval. This is useful if you’re
        # interested in the number of hits per second.
        class Rate < IntervalMetric
          TYPE = 'rate'

          def initialize(name, interval:, tags: {}, common: true)
            super

            @value = 0.0
          end

          def type
            TYPE
          end

          def track(value = 1.0)
            @value += value
            @values = [[Core::Utils::Time.now.to_i, @value / interval]]
            nil
          end
        end

        # Distribution metric represents the global statistical distribution of a set of values.
        class Distribution < Base
          TYPE = 'distributions'

          def type
            TYPE
          end

          def track(value)
            values << value
            nil
          end

          # distribution metric data does not have type field
          def to_h
            {
              metric: name,
              points: values,
              tags: tags,
              common: common
            }
          end
        end
      end
    end
  end
end
