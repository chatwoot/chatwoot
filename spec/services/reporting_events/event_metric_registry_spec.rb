require 'rails_helper'

RSpec.describe ReportingEvents::EventMetricRegistry do
  describe '.event_names' do
    it 'returns the supported raw event names' do
      expect(described_class.event_names).to eq(
        %w[
          conversation_resolved
          first_response
          reply_time
          conversation_bot_resolved
          conversation_bot_handoff
        ]
      )
    end
  end

  describe '.metrics_for' do
    it 'returns the emitted rollup metrics for conversation_resolved' do
      event = instance_double(ReportingEvent, name: 'conversation_resolved', value: 120, value_in_business_hours: 45)

      expect(described_class.metrics_for(event)).to eq(
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

      expect(described_class.metrics_for(event)).to eq(
        first_response: {
          count: 1,
          sum_value: 80.0,
          sum_value_business_hours: 20.0
        }
      )
    end

    it 'returns the emitted rollup metrics for reply_time' do
      event = instance_double(ReportingEvent, name: 'reply_time', value: 40, value_in_business_hours: 15)

      expect(described_class.metrics_for(event)).to eq(
        reply_time: {
          count: 1,
          sum_value: 40.0,
          sum_value_business_hours: 15.0
        }
      )
    end

    it 'returns the emitted rollup metrics for conversation_bot_resolved' do
      event = instance_double(ReportingEvent, name: 'conversation_bot_resolved')

      expect(described_class.metrics_for(event)).to eq(
        bot_resolutions_count: {
          count: 1,
          sum_value: 0,
          sum_value_business_hours: 0
        }
      )
    end

    it 'returns the emitted rollup metrics for conversation_bot_handoff' do
      event = instance_double(ReportingEvent, name: 'conversation_bot_handoff')

      expect(described_class.metrics_for(event)).to eq(
        bot_handoffs_count: {
          count: 1,
          sum_value: 0,
          sum_value_business_hours: 0
        }
      )
    end

    it 'returns an empty hash for unsupported events' do
      event = instance_double(ReportingEvent, name: 'conversation_created')

      expect(described_class.metrics_for(event)).to eq({})
    end
  end

  describe '.metrics_for_aggregate' do
    it 'returns aggregated rollup metrics for conversation_resolved groups' do
      expect(
        described_class.metrics_for_aggregate(
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
        described_class.metrics_for_aggregate(
          'conversation_created',
          count: 2,
          sum_value: 100,
          sum_value_business_hours: 50
        )
      ).to eq({})
    end
  end
end
