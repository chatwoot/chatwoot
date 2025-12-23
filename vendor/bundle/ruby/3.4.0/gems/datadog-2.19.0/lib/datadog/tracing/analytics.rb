# frozen_string_literal: true

require_relative 'metadata/ext'

module Datadog
  module Tracing
    # Defines analytics behavior
    module Analytics
      class << self
        def set_sample_rate(span_op, sample_rate)
          return if span_op.nil? || !sample_rate.is_a?(Numeric)

          span_op.set_metric(Metadata::Ext::Analytics::TAG_SAMPLE_RATE, sample_rate)
        end

        def set_measured(span_op, value = true)
          return if span_op.nil?

          value = value == true || value == 1 ? 1 : 0
          span_op.set_metric(Metadata::Ext::Analytics::TAG_MEASURED, value)
        end
      end
    end
  end
end
