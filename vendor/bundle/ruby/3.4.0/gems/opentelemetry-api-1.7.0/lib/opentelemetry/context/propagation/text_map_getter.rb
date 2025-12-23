# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # The default getter module provides a common methods for reading
      # key from a carrier that implements +[]+ and a +keys+ method
      class TextMapGetter
        # Reads a key from a carrier that implements +[]+. Useful for extract
        # operations.
        def get(carrier, key)
          carrier[key]
        end

        # Reads all keys from a carrier. Useful for iterating over a carrier's
        # keys.
        def keys(carrier)
          carrier.keys
        end
      end
    end
  end
end
