# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Trace module contains the OpenTelemetry tracing reference
    # implementation.
    module Trace
      # SpanData is a Struct containing {Span} data for export.
      SpanData = Struct.new(:name,                      # String
                            :kind,                      # Symbol: :internal, :producer, :consumer, :client, :server
                            :status,                    # Status
                            :parent_span_id,            # String (8 byte binary), may be OpenTelemetry::Trace::INVALID_SPAN_ID
                            :total_recorded_attributes, # Integer
                            :total_recorded_events,     # Integer
                            :total_recorded_links,      # Integer
                            :start_timestamp,           # Integer nanoseconds since Epoch
                            :end_timestamp,             # Integer nanoseconds since Epoch
                            :attributes,                # optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}
                            :links,                     # optional Array[OpenTelemetry::Trace::Link]
                            :events,                    # optional Array[Event]
                            :resource,                  # OpenTelemetry::SDK::Resources::Resource
                            :instrumentation_scope,     # OpenTelemetry::SDK::InstrumentationScope
                            :span_id,                   # String (8 byte binary)
                            :trace_id,                  # String (16-byte binary)
                            :trace_flags,               # Integer (8-bit byte of bit flags)
                            :tracestate,                # OpenTelemetry::Trace::Tracestate
                            :parent_span_is_remote) do  # Boolean (whether parent span context is remote)
                              # Returns the lowercase [hex encoded](https://tools.ietf.org/html/rfc4648#section-8) span ID.
                              #
                              # @return [String] A 16-hex-character lowercase string.
                              def hex_span_id
                                span_id.unpack1('H*')
                              end

                              # Returns the lowercase [hex encoded](https://tools.ietf.org/html/rfc4648#section-8) trace ID.
                              #
                              # @return [String] A 32-hex-character lowercase string.
                              def hex_trace_id
                                trace_id.unpack1('H*')
                              end

                              # Returns the lowercase [hex encoded](https://tools.ietf.org/html/rfc4648#section-8) parent span ID.
                              #
                              # @return [String] A 16-hex-character lowercase string.
                              def hex_parent_span_id
                                parent_span_id.unpack1('H*')
                              end

                              # Returns an InstrumentationScope struct, which is backwards compatible with InstrumentationLibrary.
                              # @deprecated Please use instrumentation_scope instead.
                              #
                              # @return InstrumentationScope
                              alias_method :instrumentation_library, :instrumentation_scope
                            end
    end
  end
end
