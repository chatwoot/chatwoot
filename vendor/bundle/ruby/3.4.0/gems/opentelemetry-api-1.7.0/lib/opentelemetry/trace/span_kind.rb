# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Trace
    # Type of span. Can be used to specify additional relationships between spans in addition to a
    # parent/child relationship. For API ergonomics, use of the symbols rather than the constants
    # may be preferred. For example:
    #
    #   span = tracer.start_span('op', kind: :client)
    module SpanKind
      # Default value. Indicates that the span is used internally.
      INTERNAL = :internal

      # Indicates that the span covers server-side handling of an RPC or other remote request.
      SERVER = :server

      # Indicates that the span covers the client-side wrapper around an RPC or other remote request.
      CLIENT = :client

      # Indicates that the span describes producer sending a message to a broker. Unlike client and
      # server, there is no direct critical path latency relationship between producer and consumer
      # spans.
      PRODUCER = :producer

      # Indicates that the span describes consumer receiving a message from a broker. Unlike client
      # and server, there is no direct critical path latency relationship between producer and
      # consumer spans.
      CONSUMER = :consumer
    end
  end
end
