# frozen_string_literal: true

require "securerandom"
require "sentry/metrics/local_aggregator"

module Sentry
  class Span
    # We will try to be consistent with OpenTelemetry on this front going forward.
    # https://develop.sentry.dev/sdk/performance/span-data-conventions/
    module DataConventions
      URL = "url"
      HTTP_STATUS_CODE = "http.response.status_code"
      HTTP_QUERY = "http.query"
      HTTP_METHOD = "http.request.method"

      # An identifier for the database management system (DBMS) product being used.
      # Example: postgresql
      DB_SYSTEM = "db.system"

      # The name of the database being accessed.
      # For commands that switch the database, this should be set to the target database
      # (even if the command fails).
      # Example: myDatabase
      DB_NAME = "db.name"

      # Name of the database host.
      # Example: example.com
      SERVER_ADDRESS = "server.address"

      # Logical server port number
      # Example: 80; 8080; 443
      SERVER_PORT = "server.port"

      # Physical server IP address or Unix socket address.
      # Example: 10.5.3.2
      SERVER_SOCKET_ADDRESS = "server.socket.address"

      # Physical server port.
      # Recommended: If different than server.port.
      # Example: 16456
      SERVER_SOCKET_PORT = "server.socket.port"

      FILEPATH = "code.filepath"
      LINENO = "code.lineno"
      FUNCTION = "code.function"
      NAMESPACE = "code.namespace"
    end

    STATUS_MAP = {
      400 => "invalid_argument",
      401 => "unauthenticated",
      403 => "permission_denied",
      404 => "not_found",
      409 => "already_exists",
      429 => "resource_exhausted",
      499 => "cancelled",
      500 => "internal_error",
      501 => "unimplemented",
      503 => "unavailable",
      504 => "deadline_exceeded"
    }

    DEFAULT_SPAN_ORIGIN = "manual"

    # An uuid that can be used to identify a trace.
    # @return [String]
    attr_reader :trace_id
    # An uuid that can be used to identify the span.
    # @return [String]
    attr_reader :span_id
    # Span parent's span_id.
    # @return [String]
    attr_reader :parent_span_id
    # Sampling result of the span.
    # @return [Boolean, nil]
    attr_reader :sampled
    # Starting timestamp of the span.
    # @return [Float]
    attr_reader :start_timestamp
    # Finishing timestamp of the span.
    # @return [Float]
    attr_reader :timestamp
    # Span description
    # @return [String]
    attr_reader :description
    # Span operation
    # @return [String]
    attr_reader :op
    # Span status
    # @return [String]
    attr_reader :status
    # Span tags
    # @return [Hash]
    attr_reader :tags
    # Span data
    # @return [Hash]
    attr_reader :data
    # Span origin that tracks what kind of instrumentation created a span
    # @return [String]
    attr_reader :origin

    # The SpanRecorder the current span belongs to.
    # SpanRecorder holds all spans under the same Transaction object (including the Transaction itself).
    # @return [SpanRecorder]
    attr_accessor :span_recorder

    # The Transaction object the Span belongs to.
    # Every span needs to be attached to a Transaction and their child spans will also inherit the same transaction.
    # @return [Transaction]
    attr_reader :transaction

    def initialize(
      transaction:,
      description: nil,
      op: nil,
      status: nil,
      trace_id: nil,
      span_id: nil,
      parent_span_id: nil,
      sampled: nil,
      start_timestamp: nil,
      timestamp: nil,
      origin: nil
    )
      @trace_id = trace_id || SecureRandom.uuid.delete("-")
      @span_id = span_id || SecureRandom.uuid.delete("-").slice(0, 16)
      @parent_span_id = parent_span_id
      @sampled = sampled
      @start_timestamp = start_timestamp || Sentry.utc_now.to_f
      @timestamp = timestamp
      @description = description
      @transaction = transaction
      @op = op
      @status = status
      @data = {}
      @tags = {}
      @origin = origin || DEFAULT_SPAN_ORIGIN
    end

    # Finishes the span by adding a timestamp.
    # @return [self]
    def finish(end_timestamp: nil)
      @timestamp = end_timestamp || @timestamp || Sentry.utc_now.to_f
      self
    end

    # Generates a trace string that can be used to connect other transactions.
    # @return [String]
    def to_sentry_trace
      sampled_flag = ""
      sampled_flag = @sampled ? 1 : 0 unless @sampled.nil?

      "#{@trace_id}-#{@span_id}-#{sampled_flag}"
    end

    # Generates a W3C Baggage header string for distributed tracing
    # from the incoming baggage stored on the transaction.
    # @return [String, nil]
    def to_baggage
      transaction.get_baggage&.serialize
    end

    # @return [Hash]
    def to_hash
      hash = {
        trace_id: @trace_id,
        span_id: @span_id,
        parent_span_id: @parent_span_id,
        start_timestamp: @start_timestamp,
        timestamp: @timestamp,
        description: @description,
        op: @op,
        status: @status,
        tags: @tags,
        data: @data,
        origin: @origin
      }

      summary = metrics_summary
      hash[:_metrics_summary] = summary if summary

      hash
    end

    # Returns the span's context that can be used to embed in an Event.
    # @return [Hash]
    def get_trace_context
      {
        trace_id: @trace_id,
        span_id: @span_id,
        parent_span_id: @parent_span_id,
        description: @description,
        op: @op,
        status: @status,
        origin: @origin,
        data: @data
      }
    end

    # Starts a child span with given attributes.
    # @param attributes [Hash] the attributes for the child span.
    def start_child(**attributes)
      attributes = attributes.dup.merge(transaction: @transaction, trace_id: @trace_id, parent_span_id: @span_id, sampled: @sampled)
      new_span = Span.new(**attributes)
      new_span.span_recorder = span_recorder

      if span_recorder
        span_recorder.add(new_span)
      end

      new_span
    end

    # Starts a child span, yield it to the given block, and then finish the span after the block is executed.
    # @example
    #   span.with_child_span do |child_span|
    #     # things happen here will be recorded in a child span
    #   end
    #
    # @param attributes [Hash] the attributes for the child span.
    # @param block [Proc] the action to be recorded in the child span.
    # @yieldparam child_span [Span]
    def with_child_span(**attributes, &block)
      child_span = start_child(**attributes)

      yield(child_span)

      child_span.finish
    rescue
      child_span.set_http_status(500)
      child_span.finish
      raise
    end

    def deep_dup
      dup
    end

    # Sets the span's operation.
    # @param op [String] operation of the span.
    def set_op(op)
      @op = op
    end

    # Sets the span's description.
    # @param description [String] description of the span.
    def set_description(description)
      @description = description
    end


    # Sets the span's status.
    # @param satus [String] status of the span.
    def set_status(status)
      @status = status
    end

    # Sets the span's finish timestamp.
    # @param timestamp [Float] finished time in float format (most precise).
    def set_timestamp(timestamp)
      @timestamp = timestamp
    end

    # Sets the span's status with given http status code.
    # @param status_code [String] example: "500".
    def set_http_status(status_code)
      status_code = status_code.to_i
      set_data(DataConventions::HTTP_STATUS_CODE, status_code)

      status =
        if status_code >= 200 && status_code < 299
          "ok"
        else
          STATUS_MAP[status_code]
        end
      set_status(status)
    end

    # Inserts a key-value pair to the span's data payload.
    # @param key [String, Symbol]
    # @param value [Object]
    def set_data(key, value)
      @data[key] = value
    end

    # Sets a tag to the span.
    # @param key [String, Symbol]
    # @param value [String]
    def set_tag(key, value)
      @tags[key] = value
    end

    # Sets the origin of the span.
    # @param origin [String]
    def set_origin(origin)
      @origin = origin
    end

    # Collects gauge metrics on the span for metric summaries.
    def metrics_local_aggregator
      @metrics_local_aggregator ||= Sentry::Metrics::LocalAggregator.new
    end

    def metrics_summary
      @metrics_local_aggregator&.to_hash
    end
  end
end
