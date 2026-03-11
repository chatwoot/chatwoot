require 'rails_helper'

RSpec.describe ReportingEvents::MetricRegistry do
  describe '.event_metrics_for' do
    it 'returns the emitted rollup metrics for conversation_resolved' do
      event = instance_double(ReportingEvent, name: 'conversation_resolved', value: 120, value_in_business_hours: 45)

      expect(described_class.event_metrics_for(event)).to eq(
        resolutions_count: {
          count: 1,
          sum_value: 0,
          sum_value_business_hours: 0
        },
        resolution_time: {
          count: 1,
          sum_value: 120.0,
          sum_value_business_hours: 45.0
        }
      )
    end

    it 'returns the emitted rollup metrics for first_response' do
      event = instance_double(ReportingEvent, name: 'first_response', value: 80, value_in_business_hours: 20)

      expect(described_class.event_metrics_for(event)).to eq(
        first_response: {
          count: 1,
          sum_value: 80.0,
          sum_value_business_hours: 20.0
        }
      )
    end

    it 'returns the emitted rollup metrics for reply_time' do
      event = instance_double(ReportingEvent, name: 'reply_time', value: 40, value_in_business_hours: 15)

      expect(described_class.event_metrics_for(event)).to eq(
        reply_time: {
          count: 1,
          sum_value: 40.0,
          sum_value_business_hours: 15.0
        }
      )
    end

    it 'returns the emitted rollup metrics for conversation_bot_resolved' do
      event = instance_double(ReportingEvent, name: 'conversation_bot_resolved')

      expect(described_class.event_metrics_for(event)).to eq(
        bot_resolutions_count: {
          count: 1,
          sum_value: 0,
          sum_value_business_hours: 0
        }
      )
    end

    it 'returns the emitted rollup metrics for conversation_bot_handoff' do
      event = instance_double(ReportingEvent, name: 'conversation_bot_handoff')

      expect(described_class.event_metrics_for(event)).to eq(
        bot_handoffs_count: {
          count: 1,
          sum_value: 0,
          sum_value_business_hours: 0
        }
      )
    end

    it 'returns an empty hash for unsupported events' do
      event = instance_double(ReportingEvent, name: 'conversation_created')

      expect(described_class.event_metrics_for(event)).to eq({})
    end
  end

  describe '.event_metrics_for_aggregate' do
    it 'returns aggregated rollup metrics for conversation_resolved groups' do
      expect(
        described_class.event_metrics_for_aggregate(
          'conversation_resolved',
          count: 3,
          sum_value: 420,
          sum_value_business_hours: 210
        )
      ).to eq(
        resolutions_count: {
          count: 3,
          sum_value: 0,
          sum_value_business_hours: 0
        },
        resolution_time: {
          count: 3,
          sum_value: 420.0,
          sum_value_business_hours: 210.0
        }
      )
    end

    it 'returns an empty hash for unsupported grouped events' do
      expect(
        described_class.event_metrics_for_aggregate(
          'conversation_created',
          count: 2,
          sum_value: 100,
          sum_value_business_hours: 50
        )
      ).to eq({})
    end
  end

  describe '.report_metric' do
    it 'returns the definition for raw-only count metrics' do
      expect(described_class.report_metric(:conversations_count)).to eq(
        aggregate: :count
      )
    end

    it 'returns the definition for avg_resolution_time' do
      expect(described_class.report_metric(:avg_resolution_time)).to eq(
        raw_event_name: :conversation_resolved,
        rollup_metric: :resolution_time,
        aggregate: :average
      )
    end

    it 'locks the distinct conversation strategy for bot_handoffs_count' do
      expect(described_class.report_metric(:bot_handoffs_count)).to eq(
        raw_event_name: :conversation_bot_handoff,
        rollup_metric: :bot_handoffs_count,
        aggregate: :count,
        raw_count_strategy: :distinct_conversation
      )
    end

    it 'returns nil for unsupported metrics' do
      expect(described_class.report_metric(:unknown_metric)).to be_nil
    end
  end

  describe '.supported_metric?' do
    it 'returns true for supported raw-only metrics' do
      expect(described_class.supported_metric?(:conversations_count)).to be(true)
    end

    it 'returns false for unsupported metrics' do
      expect(described_class.supported_metric?(:unknown_metric)).to be(false)
    end
  end

  describe '.aggregate_for' do
    it 'returns the aggregate type for a supported metric' do
      expect(described_class.aggregate_for(:avg_first_response_time)).to eq(:average)
    end
  end

  describe '.rollup_supported_metric?' do
    it 'returns true for rollup-backed metrics' do
      expect(described_class.rollup_supported_metric?(:reply_time)).to be(true)
    end

    it 'returns false for unsupported metrics' do
      expect(described_class.rollup_supported_metric?(:conversations_count)).to be(false)
    end
  end

  describe '.rollup_metric_for' do
    it 'returns the rollup metric name' do
      expect(described_class.rollup_metric_for(:avg_first_response_time)).to eq(:first_response)
    end
  end

  describe '.raw_event_name_for' do
    it 'returns the raw event name' do
      expect(described_class.raw_event_name_for(:bot_resolutions_count)).to eq(:conversation_bot_resolved)
    end
  end
end
