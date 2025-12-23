# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Trace module contains the OpenTelemetry tracing reference
    # implementation.
    module Trace
    end
  end
end

require 'opentelemetry/sdk/trace/samplers'
require 'opentelemetry/sdk/trace/span_limits'
require 'opentelemetry/sdk/trace/event'
require 'opentelemetry/sdk/trace/export'
require 'opentelemetry/sdk/trace/span_data'
require 'opentelemetry/sdk/trace/span_processor'
require 'opentelemetry/sdk/trace/span'
require 'opentelemetry/sdk/trace/tracer'
require 'opentelemetry/sdk/trace/tracer_provider'
