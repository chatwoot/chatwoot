# frozen_string_literal: true

module Sentry
  module Metrics
    class Aggregator < ThreadedPeriodicWorker
      FLUSH_INTERVAL = 5
      ROLLUP_IN_SECONDS = 10

      # this is how far removed from user code in the backtrace we are
      # when we record code locations
      DEFAULT_STACKLEVEL = 4

      KEY_SANITIZATION_REGEX = /[^a-zA-Z0-9_\-.]+/
      UNIT_SANITIZATION_REGEX = /[^a-zA-Z0-9_]+/
      TAG_KEY_SANITIZATION_REGEX = /[^a-zA-Z0-9_\-.\/]+/

      TAG_VALUE_SANITIZATION_MAP = {
        "\n" => "\\n",
        "\r" => "\\r",
        "\t" => "\\t",
        "\\" => "\\\\",
        "|" => "\\u{7c}",
        "," => "\\u{2c}"
      }

      METRIC_TYPES = {
        c: CounterMetric,
        d: DistributionMetric,
        g: GaugeMetric,
        s: SetMetric
      }

      # exposed only for testing
      attr_reader :client, :thread, :buckets, :flush_shift, :code_locations

      def initialize(configuration, client)
        super(configuration.logger, FLUSH_INTERVAL)
        @client = client
        @before_emit = configuration.metrics.before_emit
        @enable_code_locations = configuration.metrics.enable_code_locations
        @stacktrace_builder = configuration.stacktrace_builder

        @default_tags = {}
        @default_tags['release'] = configuration.release if configuration.release
        @default_tags['environment'] = configuration.environment if configuration.environment

        @mutex = Mutex.new

        # a nested hash of timestamp -> bucket keys -> Metric instance
        @buckets = {}

        # the flush interval needs to be shifted once per startup to create jittering
        @flush_shift = Random.rand * ROLLUP_IN_SECONDS

        # a nested hash of timestamp (start of day) -> meta keys -> frame
        @code_locations = {}
      end

      def add(type,
              key,
              value,
              unit: 'none',
              tags: {},
              timestamp: nil,
              stacklevel: nil)
        return unless ensure_thread
        return unless METRIC_TYPES.keys.include?(type)

        updated_tags = get_updated_tags(tags)
        return if @before_emit && !@before_emit.call(key, updated_tags)

        timestamp ||= Sentry.utc_now

        # this is integer division and thus takes the floor of the division
        # and buckets into 10 second intervals
        bucket_timestamp = (timestamp.to_i / ROLLUP_IN_SECONDS) * ROLLUP_IN_SECONDS

        serialized_tags = serialize_tags(updated_tags)
        bucket_key = [type, key, unit, serialized_tags]

        added = @mutex.synchronize do
          record_code_location(type, key, unit, timestamp, stacklevel: stacklevel) if @enable_code_locations
          process_bucket(bucket_timestamp, bucket_key, type, value)
        end

        # for sets, we pass on if there was a new entry to the local gauge
        local_value = type == :s ? added : value
        process_span_aggregator(bucket_key, local_value)
      end

      def flush(force: false)
        flushable_buckets = get_flushable_buckets!(force)
        code_locations = get_code_locations!
        return if flushable_buckets.empty? && code_locations.empty?

        envelope = Envelope.new

        unless flushable_buckets.empty?
          payload = serialize_buckets(flushable_buckets)
          envelope.add_item(
            { type: 'statsd', length: payload.bytesize },
            payload
          )
        end

        unless code_locations.empty?
          code_locations.each do |timestamp, locations|
            payload = serialize_locations(timestamp, locations)
            envelope.add_item(
              { type: 'metric_meta', content_type: 'application/json' },
              payload
            )
          end
        end

        @client.capture_envelope(envelope)
      end

      alias_method :run, :flush

      private

      # important to sort for key consistency
      def serialize_tags(tags)
        tags.flat_map do |k, v|
          if v.is_a?(Array)
            v.map { |x| [k.to_s, x.to_s] }
          else
            [[k.to_s, v.to_s]]
          end
        end.sort
      end

      def get_flushable_buckets!(force)
        @mutex.synchronize do
          flushable_buckets = {}

          if force
            flushable_buckets = @buckets
            @buckets = {}
          else
            cutoff = Sentry.utc_now.to_i - ROLLUP_IN_SECONDS - @flush_shift
            flushable_buckets = @buckets.select { |k, _| k <= cutoff }
            @buckets.reject! { |k, _| k <= cutoff }
          end

          flushable_buckets
        end
      end

      def get_code_locations!
        @mutex.synchronize do
          code_locations = @code_locations
          @code_locations = {}
          code_locations
        end
      end

      # serialize buckets to statsd format
      def serialize_buckets(buckets)
        buckets.map do |timestamp, timestamp_buckets|
          timestamp_buckets.map do |metric_key, metric|
            type, key, unit, tags = metric_key
            values = metric.serialize.join(':')
            sanitized_tags = tags.map { |k, v| "#{sanitize_tag_key(k)}:#{sanitize_tag_value(v)}" }.join(',')

            "#{sanitize_key(key)}@#{sanitize_unit(unit)}:#{values}|#{type}|\##{sanitized_tags}|T#{timestamp}"
          end
        end.flatten.join("\n")
      end

      def serialize_locations(timestamp, locations)
        mapping = locations.map do |meta_key, location|
          type, key, unit = meta_key
          mri = "#{type}:#{sanitize_key(key)}@#{sanitize_unit(unit)}"

          # note this needs to be an array but it really doesn't serve a purpose right now
          [mri, [location.merge(type: 'location')]]
        end.to_h

        { timestamp: timestamp, mapping: mapping }
      end

      def sanitize_key(key)
        key.gsub(KEY_SANITIZATION_REGEX, '_')
      end

      def sanitize_unit(unit)
        unit.gsub(UNIT_SANITIZATION_REGEX, '')
      end

      def sanitize_tag_key(key)
        key.gsub(TAG_KEY_SANITIZATION_REGEX, '')
      end

      def sanitize_tag_value(value)
        value.chars.map { |c| TAG_VALUE_SANITIZATION_MAP[c] || c }.join
      end

      def get_transaction_name
        scope = Sentry.get_current_scope
        return nil unless scope && scope.transaction_name
        return nil if scope.transaction_source_low_quality?

        scope.transaction_name
      end

      def get_updated_tags(tags)
        updated_tags = @default_tags.merge(tags)

        transaction_name = get_transaction_name
        updated_tags['transaction'] = transaction_name if transaction_name

        updated_tags
      end

      def process_span_aggregator(key, value)
        scope = Sentry.get_current_scope
        return nil unless scope && scope.span
        return nil if scope.transaction_source_low_quality?

        scope.span.metrics_local_aggregator.add(key, value)
      end

      def process_bucket(timestamp, key, type, value)
        @buckets[timestamp] ||= {}

        if (metric = @buckets[timestamp][key])
          old_weight = metric.weight
          metric.add(value)
          metric.weight - old_weight
        else
          metric = METRIC_TYPES[type].new(value)
          @buckets[timestamp][key] = metric
          metric.weight
        end
      end

      def record_code_location(type, key, unit, timestamp, stacklevel: nil)
        meta_key =  [type, key, unit]
        start_of_day = Time.utc(timestamp.year, timestamp.month, timestamp.day).to_i

        @code_locations[start_of_day] ||= {}
        @code_locations[start_of_day][meta_key] ||= @stacktrace_builder.metrics_code_location(caller[stacklevel || DEFAULT_STACKLEVEL])
      end
    end
  end
end
