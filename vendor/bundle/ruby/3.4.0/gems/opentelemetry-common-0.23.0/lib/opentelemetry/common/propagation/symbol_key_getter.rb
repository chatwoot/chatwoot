# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Common
    module Propagation
      # The SymbolKeyGetter class provides a common method for reading
      # symbol keys from a hash.
      class SymbolKeyGetter
        # Converts key into a symbol and reads it from the carrier.
        # Useful for extract operations.
        def get(carrier, key)
          carrier[key.to_sym]
        end

        # Reads all keys from a carrier
        def keys(carrier)
          carrier.keys.map(&:to_s)
        end
      end
    end
  end
end
