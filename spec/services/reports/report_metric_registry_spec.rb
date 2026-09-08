require 'rails_helper'

RSpec.describe Reports::ReportMetricRegistry do
  describe '.fetch' do
    it 'returns the definition for raw-only count metrics' do
      metric = described_class.fetch(:conversations_count)

      expect(metric.name).to eq(:conversations_count)
      expect(metric.count?).to be(true)
      expect(metric.rollup_supported?).to be(false)
      expect(metric.raw_event_name).to be_nil
    end

    it 'returns the definition for avg_resolution_time' do
      metric = described_class.fetch(:avg_resolution_time)

      expect(metric.name).to eq(:avg_resolution_time)
      expect(metric.average?).to be(true)
      expect(metric.raw_event_name).to eq(:conversation_resolved)
      expect(metric.rollup_metric).to eq(:resolution_time)
      expect(metric.summary_key).to eq(:avg_resolution_time)
    end

    it 'locks the distinct conversation strategy for bot_handoffs_count' do
      metric = described_class.fetch(:bot_handoffs_count)

      expect(metric.count?).to be(true)
      expect(metric.raw_event_name).to eq(:conversation_bot_handoff)
      expect(metric.rollup_metric).to eq(:bot_handoffs_count)
      expect(metric.raw_count_strategy).to eq(:distinct_conversation)
    end

    it 'locks the handoff exclusion strategy for bot_resolutions_count' do
      metric = described_class.fetch(:bot_resolutions_count)

      expect(metric.count?).to be(true)
      expect(metric.raw_event_name).to eq(:conversation_bot_resolved)
      expect(metric.rollup_metric).to eq(:bot_resolutions_count)
      expect(metric.raw_count_strategy).to eq(:exclude_bot_handoffs)
    end

    it 'returns nil for unsupported metrics' do
      expect(described_class.fetch(:unknown_metric)).to be_nil
    end
  end

  describe '.supported?' do
    it 'returns true for supported raw-only metrics' do
      expect(described_class.supported?(:conversations_count)).to be(true)
    end

    it 'returns false for unsupported metrics' do
      expect(described_class.supported?(:unknown_metric)).to be(false)
    end
  end

  describe '.rollup_supported?' do
    it 'returns true for rollup-backed metrics' do
      expect(described_class.rollup_supported?(:reply_time)).to be(true)
    end

    it 'returns false for raw-only metrics' do
      expect(described_class.rollup_supported?(:conversations_count)).to be(false)
    end
  end

  describe '.summary_metrics' do
    it 'returns the summary metric definitions in registry order' do
      expect(
        described_class.summary_metrics.map do |metric|
          [metric.name, metric.summary_key, metric.aggregate, metric.raw_event_name, metric.rollup_metric]
        end
      ).to eq(
        [
          [:resolutions_count, :resolved_conversations_count, :count, :conversation_resolved, :resolutions_count],
          [:avg_resolution_time, :avg_resolution_time, :average, :conversation_resolved, :resolution_time],
          [:avg_first_response_time, :avg_first_response_time, :average, :first_response, :first_response],
          [:reply_time, :avg_reply_time, :average, :reply_time, :reply_time]
        ]
      )
    end
  end
end
