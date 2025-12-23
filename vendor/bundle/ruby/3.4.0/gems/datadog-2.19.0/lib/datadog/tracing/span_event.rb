# frozen_string_literal: true

require 'time'

module Datadog
  module Tracing
    # Represents a timestamped annotation on a span. It is analogous to structured log message.
    # @public_api
    class SpanEvent
      # @!attribute [r] name
      #   @return [Integer]
      attr_reader :name

      # @!attribute [r] attributes
      #   @return [Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}]
      attr_reader :attributes

      # @!attribute [r] time_unix_nano
      #   @return [Integer]
      attr_reader :time_unix_nano

      # TODO: Accept {Time} as the time_unix_nano parameter, possibly in addition to the current nano integer.
      def initialize(
        name,
        attributes: nil,
        time_unix_nano: nil
      )
        @name = name

        @attributes = attributes.dup || {}
        validate_attributes!(@attributes)
        @attributes.transform_keys!(&:to_s)

        # OpenTelemetry SDK stores span event timestamps in nanoseconds (not seconds).
        # We will do the same here to avoid unnecessary conversions and inconsistencies.
        @time_unix_nano = time_unix_nano || (Core::Utils::Time.now.to_r * 1_000_000_000).to_i
      end

      # Converts the span event into a hash to be used by with the span tag serialization
      # (`span.set_tag('events) = [event.to_hash]`). This serialization format has the drawback
      # of being limiting span events to the size limit of a span tag.
      # All Datadog agents support this format.
      def to_hash
        h = { 'name' => @name, 'time_unix_nano' => @time_unix_nano }
        h['attributes'] = @attributes unless @attributes.empty?
        h
      end

      # Converts the span event into a hash to be used by the MessagePack serialization as a
      # top-level span field (span.span_events = [event.to_native_format]).
      # This serialization format removes the serialization limitations of the `span.set_tag('events)` approach,
      # but is only supported by newer version of the Datadog agent.
      def to_native_format
        h = { 'name' => @name, 'time_unix_nano' => @time_unix_nano }

        attr = {}
        @attributes.each do |key, value|
          attr[key] = if value.is_a?(Array)
                        { type: ARRAY_TYPE, array_value: { values: value.map { |v| serialize_native_attribute(v) } } }
                      else
                        serialize_native_attribute(value)
                      end
        end

        h['attributes'] = attr unless @attributes.empty?

        h
      end

      private

      MIN_INT64_SIGNED = -2**63
      MAX_INT64_SIGNED = 2 << 63 - 1

      # Checks the attributes hash to ensure it only contains serializable values.
      # Invalid values are removed from the hash.
      def validate_attributes!(attributes)
        attributes.select! do |key, value|
          case value
          when Array
            next true if value.empty?

            first = value.first
            case first
            when String, Integer, Float
              first_type = first.class
              if value.all? { |v| v.is_a?(first_type) }
                value.all? { |v| validate_scalar_attribute!(key, v) }
              else
                Datadog.logger.warn("Attribute #{key} array must be homogenous: #{value}.")
                false
              end
            when TrueClass, FalseClass
              if value.all? { |v| v.is_a?(TrueClass) || v.is_a?(FalseClass) }
                value.all? { |v| validate_scalar_attribute!(key, v) }
              else
                Datadog.logger.warn("Attribute #{key} array must be homogenous: #{value}.")
                false
              end
            else
              Datadog.logger.warn("Attribute #{key} must be a string, number, or boolean: #{value}.")
              false
            end
          when String, Numeric, TrueClass, FalseClass
            validate_scalar_attribute!(key, value)
          else
            Datadog.logger.warn("Attribute #{key} must be a string, number, boolean, or array: #{value}.")
            false
          end
        end
      end

      def validate_scalar_attribute!(key, value)
        case value
        when String, TrueClass, FalseClass
          true
        when Integer
          # Cannot be larger than signed 64-bit integer
          if value < MIN_INT64_SIGNED || value > MAX_INT64_SIGNED
            Datadog.logger.warn("Attribute #{key} must be within the range of a signed 64-bit integer: #{value}.")
            false
          else
            true
          end
        when Float
          # Has to be finite
          return true if value.finite?

          Datadog.logger.warn("Attribute #{key} must be a finite number: #{value}.")
          false
        else
          Datadog.logger.warn("Attribute #{key} must be a string, number, or boolean: #{value}.")
          false
        end
      end

      STRING_TYPE = 0
      BOOLEAN_TYPE = 1
      INTEGER_TYPE = 2
      DOUBLE_TYPE = 3
      ARRAY_TYPE = 4

      # Serializes individual scalar attributes into the native format.
      def serialize_native_attribute(value)
        case value
        when String
          { type: STRING_TYPE, string_value: value }
        when TrueClass, FalseClass
          { type: BOOLEAN_TYPE, bool_value: value }
        when Integer
          { type: INTEGER_TYPE, int_value: value }
        when Float
          { type: DOUBLE_TYPE, double_value: value }
        else
          # This is technically unreachable due to the validation in #initialize.
          raise ArgumentError, "Attribute must be a string, number, or boolean: #{value}."
        end
      end
    end
  end
end
