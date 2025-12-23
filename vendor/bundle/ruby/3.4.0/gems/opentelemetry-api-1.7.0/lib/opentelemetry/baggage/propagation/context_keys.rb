# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Baggage
    module Propagation
      # The ContextKeys module contains the keys used to index baggage
      # in a {Context} instance
      module ContextKeys
        extend self

        BAGGAGE_KEY = Context.create_key('baggage')
        private_constant :BAGGAGE_KEY

        # Returns the context key that baggage are indexed by
        #
        # @return [Context::Key]
        def baggage_key
          BAGGAGE_KEY
        end
      end
    end
  end
end
