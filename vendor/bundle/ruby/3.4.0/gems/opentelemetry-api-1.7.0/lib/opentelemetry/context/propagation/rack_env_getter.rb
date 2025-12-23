# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # @deprecated Use the rack env getter found in the
      # opentelemetry-common gem instead.

      # The RackEnvGetter class provides a common methods for reading
      # keys from a rack environment. It abstracts away the rack-normalization
      # process so that keys can be looked up without having to transform them
      # first. With this class you can get +traceparent+ instead of
      # +HTTP_TRACEPARENT+
      class RackEnvGetter
        # Converts key into a rack-normalized key and reads it from the carrier.
        # Useful for extract operations.
        def get(carrier, key)
          carrier[to_rack_key(key)] || carrier[key]
        end

        # Reads all keys from a carrier and converts them from the rack-normalized
        # form to the original. The resulting keys will be lowercase and
        # underscores will be replaced with dashes.
        def keys(carrier)
          carrier.keys.map(&method(:from_rack_key))
        end

        private

        def to_rack_key(key)
          # Use + for mutable string interpolation in pre-Ruby 3.0.
          ret = +"HTTP_#{key}"
          ret.tr!('-', '_')
          ret.upcase!
          ret
        end

        def from_rack_key(key)
          start = key.start_with?('HTTP_') ? 5 : 0
          ret = key[start..]
          ret.tr!('_', '-')
          ret.downcase!
          ret
        end
      end
    end
  end
end
