# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # The default setter module provides a common method for writing
      # a key into a carrier that implements +[]=+
      class TextMapSetter
        # Writes key into a carrier that implements +[]=+. Useful for inject
        # operations.
        def set(carrier, key, value)
          carrier[key] = value
        end
      end
    end
  end
end
