# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/baggage/propagation/context_keys'
require 'opentelemetry/baggage/propagation/text_map_propagator'

module OpenTelemetry
  module Baggage
    # The Baggage::Propagation module contains a text map propagator for
    # sending and receiving baggage over the wire.
    module Propagation
      extend self

      TEXT_MAP_PROPAGATOR = TextMapPropagator.new

      private_constant :TEXT_MAP_PROPAGATOR

      # Returns a text map propagator that propagates context using the
      # W3C Baggage format.
      def text_map_propagator
        TEXT_MAP_PROPAGATOR
      end
    end
  end
end
