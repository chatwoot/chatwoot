# frozen_string_literal: true

require_relative '../core/utils/forking'
require_relative '../core/utils/time'

module Datadog
  module Tracing
    # Utils contains low-level tracing utility functions.
    # @public_api
    module Utils
      extend Datadog::Core::Utils::Forking

      # The max value for a {Datadog::Tracing::Span} identifier.
      # Span and trace identifiers should be strictly positive and strictly inferior to this limit.
      #
      # Limited to +2<<62-1+ positive integers, as Ruby is able to represent such numbers "inline",
      # inside a +VALUE+ scalar, thus not requiring memory allocation.
      #
      # The range of IDs also has to consider portability across different languages and platforms.
      RUBY_MAX_ID = (1 << 62) - 1

      # Excludes zero from possible values
      RUBY_ID_RANGE = (1..RUBY_MAX_ID).freeze

      # While we only generate 63-bit integers due to limitations in other languages, we support
      # parsing 64-bit integers for distributed tracing since an upstream system may generate one
      EXTERNAL_MAX_ID = (1 << 64) - 1

      # We use a custom random number generator because we want no interference
      # with the default one. Using the default prng, we could break code that
      # would rely on srand/rand sequences.

      # Return a randomly generated integer, valid as a Span ID or Trace ID.
      # This method is thread-safe and fork-safe.
      def self.next_id
        after_fork! { reset! }
        id_rng.rand(RUBY_ID_RANGE)
      end

      def self.id_rng
        @id_rng ||= Random.new
      end

      def self.reset!
        @id_rng = Random.new
      end

      # Serialize values into Datadog span tags and metrics.
      # Notably, arrays are exploded into many keys, each with
      # a numeric suffix representing the array index, for example:
      # `'foo' => ['a','b']` becomes `'foo.0' => 'a', 'foo.1' => 'b'`
      def self.serialize_attribute(key, value)
        if value.is_a?(Array)
          value.flat_map.with_index do |v, idx|
            serialize_attribute("#{key}.#{idx}", v)
          end
        elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
          [[key, value.to_s]]
        else
          [[key, value]]
        end
      end

      private_class_method :id_rng, :reset!

      # The module handles bitwise operation for trace id
      module TraceId
        MAX = (1 << 128) - 1

        module_function

        # Format for generating 128 bits trace id =>
        # - 32-bits : seconds since Epoch
        # - 32-bits : set to zero,
        # - 64 bits : random 64-bits
        def next_id
          return Utils.next_id unless Datadog.configuration.tracing.trace_id_128_bit_generation_enabled

          concatenate(
            Core::Utils::Time.now.to_i << 32,
            Utils.next_id
          )
        end

        def to_high_order(trace_id)
          trace_id >> 64
        end

        def to_low_order(trace_id)
          trace_id & 0xFFFFFFFFFFFFFFFF
        end

        def concatenate(high_order, low_order)
          high_order << 64 | low_order
        end
      end
    end
  end
end
