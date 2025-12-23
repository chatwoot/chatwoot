# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/trace/propagation/trace_context/trace_parent'
require 'opentelemetry/trace/propagation/trace_context/text_map_propagator'

module OpenTelemetry
  module Trace
    module Propagation
      # The TraceContext module contains injectors, extractors, and utilities
      # for context propagation in the W3C Trace Context format.
      module TraceContext
        extend self
        TEXT_MAP_PROPAGATOR = TextMapPropagator.new

        private_constant :TEXT_MAP_PROPAGATOR

        # Returns a text map propagator that propagates context using the
        # W3C Trace Context format.
        def text_map_propagator
          TEXT_MAP_PROPAGATOR
        end
      end
    end
  end
end
