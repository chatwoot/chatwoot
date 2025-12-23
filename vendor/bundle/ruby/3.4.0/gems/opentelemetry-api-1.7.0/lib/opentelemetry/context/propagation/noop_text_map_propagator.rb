# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # @api private
      class NoopTextMapPropagator
        EMPTY_LIST = [].freeze
        private_constant(:EMPTY_LIST)

        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter); end

        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          context
        end

        def fields
          EMPTY_LIST
        end
      end
    end
  end
end
