# frozen_string_literal: true

module Aloo
  class Trace < ApplicationRecord
    self.table_name = 'aloo_traces'

    include Aloo::AccountScoped

    belongs_to :assistant,
               class_name: 'Aloo::Assistant',
               foreign_key: 'aloo_assistant_id',
               optional: true,
               inverse_of: :traces
    belongs_to :conversation, optional: true

    TRACE_TYPES = %w[agent_call search tool_execution embedding].freeze

    validates :trace_type, inclusion: { in: TRACE_TYPES }

    # Truncate long error messages before save
    before_validation :truncate_error_message

    scope :recent, -> { where('created_at > ?', 24.hours.ago) }
    scope :failed, -> { where(success: false) }
    scope :successful, -> { where(success: true) }
    scope :by_type, ->(type) { where(trace_type: type) }
    scope :by_request, ->(request_id) { where(request_id: request_id) }

    class << self
      # Record a trace with automatic request_id from Current
      def record(trace_type:, account:, **attrs)
        # Truncate error message if too long
        if attrs[:error_message].present? && attrs[:error_message].length > 255
          attrs[:error_message] = attrs[:error_message].truncate(255)
        end

        create!(
          trace_type: trace_type,
          account: account,
          request_id: attrs[:request_id] || Aloo::Current.request_id,
          **attrs.except(:request_id)
        )
      end

      # Record with timing block
      def record_with_timing(trace_type:, account:, **attrs)
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = nil
        success = true
        error_message = nil

        begin
          result = yield
        rescue StandardError => e
          success = false
          error_message = e.message.truncate(255) if e.message.present?
          raise
        ensure
          duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

          record(
            trace_type: trace_type,
            account: account,
            duration_ms: duration_ms,
            success: success,
            error_message: error_message,
            **attrs
          )
        end

        result
      end
    end

    def duration_seconds
      duration_ms.to_f / 1000.0 if duration_ms
    end

    def total_tokens
      (input_tokens || 0) + (output_tokens || 0)
    end

    # Calculate approximate cost (rough estimates)
    def estimated_cost
      return 0 unless input_tokens && output_tokens

      # Rough pricing for common models (per 1M tokens)
      input_cost_per_million = 0.15  # $0.15 per 1M input tokens
      output_cost_per_million = 0.60 # $0.60 per 1M output tokens

      (input_tokens * input_cost_per_million / 1_000_000.0) +
        (output_tokens * output_cost_per_million / 1_000_000.0)
    end

    private

    def truncate_error_message
      self.error_message = error_message.truncate(255) if error_message.present?
    end
  end
end
