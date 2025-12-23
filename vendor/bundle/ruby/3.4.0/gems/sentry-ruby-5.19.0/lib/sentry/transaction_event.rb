# frozen_string_literal: true

module Sentry
  # TransactionEvent represents events that carry transaction data (type: "transaction").
  class TransactionEvent < Event
    TYPE = "transaction"

    # @return [<Array[Span]>]
    attr_accessor :spans

    # @return [Hash]
    attr_accessor :measurements

    # @return [Float, nil]
    attr_reader :start_timestamp

    # @return [Hash, nil]
    attr_accessor :profile

    # @return [Hash, nil]
    attr_accessor :metrics_summary

    def initialize(transaction:, **options)
      super(**options)

      self.transaction = transaction.name
      self.transaction_info = { source: transaction.source }
      self.contexts.merge!(transaction.contexts)
      self.contexts.merge!(trace: transaction.get_trace_context)
      self.timestamp = transaction.timestamp
      self.start_timestamp = transaction.start_timestamp
      self.tags = transaction.tags
      self.dynamic_sampling_context = transaction.get_baggage.dynamic_sampling_context
      self.measurements = transaction.measurements
      self.metrics_summary = transaction.metrics_summary

      finished_spans = transaction.span_recorder.spans.select { |span| span.timestamp && span != transaction }
      self.spans = finished_spans.map(&:to_hash)

      populate_profile(transaction)
    end

    # Sets the event's start_timestamp.
    # @param time [Time, Float]
    # @return [void]
    def start_timestamp=(time)
      @start_timestamp = time.is_a?(Time) ? time.to_f : time
    end

    # @return [Hash]
    def to_hash
      data = super
      data[:spans] = @spans.map(&:to_hash) if @spans
      data[:start_timestamp] = @start_timestamp
      data[:measurements] = @measurements
      data[:_metrics_summary] = @metrics_summary if @metrics_summary
      data
    end

    private

    def populate_profile(transaction)
      profile_hash = transaction.profiler.to_hash
      return if profile_hash.empty?

      profile_hash.merge!(
        environment: environment,
        release: release,
        timestamp: Time.at(start_timestamp).iso8601,
        device: { architecture: Scope.os_context[:machine] },
        os: { name: Scope.os_context[:name], version: Scope.os_context[:version] },
        runtime: Scope.runtime_context,
        transaction: {
          id: event_id,
          name: transaction.name,
          trace_id: transaction.trace_id,
          # TODO-neel-profiler stubbed for now, see thread_id note in profiler.rb
          active_thead_id: '0'
        }
      )

      self.profile = profile_hash
    end
  end
end
