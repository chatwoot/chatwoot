require 'rails_helper'

RSpec.describe Captain::AssistantResolutionTrendStatsBuilder do
  subject(:metrics) { described_class.new(assistant, range, timezone_offset).metrics }

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:range) { 'this_month' }
  let(:timezone_offset) { 0 }
  let(:now) { Time.zone.parse('2025-06-30 12:00:00') }

  around do |example|
    travel_to(now) { example.run }
  end

  context 'with no outcomes' do
    it 'returns zeroed weekly buckets for the complete reporting window' do
      expect(metrics).to eq(
        granularity: :week,
        buckets: [
          { starts_on: Date.new(2025, 6, 1), ends_on: Date.new(2025, 6, 7), conversations_handled: 0, resolved_by_captain: 0,
            current_resolution_rate: nil, previous_resolution_rate: nil },
          { starts_on: Date.new(2025, 6, 8), ends_on: Date.new(2025, 6, 14), conversations_handled: 0, resolved_by_captain: 0,
            current_resolution_rate: nil, previous_resolution_rate: nil },
          { starts_on: Date.new(2025, 6, 15), ends_on: Date.new(2025, 6, 21), conversations_handled: 0, resolved_by_captain: 0,
            current_resolution_rate: nil, previous_resolution_rate: nil },
          { starts_on: Date.new(2025, 6, 22), ends_on: Date.new(2025, 6, 28), conversations_handled: 0, resolved_by_captain: 0,
            current_resolution_rate: nil, previous_resolution_rate: nil },
          { starts_on: Date.new(2025, 6, 29), ends_on: Date.new(2025, 6, 30), conversations_handled: 0, resolved_by_captain: 0,
            current_resolution_rate: nil, previous_resolution_rate: nil }
        ]
      )
    end
  end

  context 'when the reporting window spans 15 days or less' do
    let(:now) { Time.zone.parse('2025-06-15 12:00:00') }

    it 'returns zeroed daily buckets' do
      expect(metrics[:granularity]).to eq(:day)
      expect(metrics[:buckets].map { |bucket| bucket.values_at(:starts_on, :ends_on) }).to eq(
        (Date.new(2025, 6, 1)..Date.new(2025, 6, 15)).map { |date| [date, date] }
      )
      expect(metrics[:buckets]).to all(include(conversations_handled: 0, resolved_by_captain: 0))
    end

    it 'computes every bucket in one outcome query' do
      queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        queries << payload[:sql] if payload[:sql].include?('FROM "conversation_outcomes"') && !payload[:cached]
      end

      ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') { metrics }

      expect(queries.size).to eq(1)
    end
  end

  context 'with outcomes across the reporting window' do
    before do
      first_week_start = Time.zone.parse('2025-06-01 12:00:00')
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: first_week_start,
        first_captain_reply_at: first_week_start + 1.minute,
        resolved_at: first_week_start + 1.hour
      )

      second_week_start = Time.zone.parse('2025-06-08 00:00:00')
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: second_week_start,
        handoff_at: second_week_start + 1.minute,
        handoff_reason_category: 'customer_request'
      )

      usage_limit_start = Time.zone.parse('2025-06-09 12:00:00')
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: usage_limit_start,
        handoff_at: usage_limit_start + 1.minute,
        handoff_reason_category: 'usage_limit'
      )

      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: Time.zone.parse('2025-06-15 12:00:00')
      )

      fourth_week_start = Time.zone.parse('2025-06-22 12:00:00')
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: fourth_week_start,
        first_captain_reply_at: fourth_week_start + 1.minute,
        first_human_reply_at: fourth_week_start + 2.minutes,
        resolved_at: fourth_week_start + 1.hour
      )

      final_week_start = Time.zone.parse('2025-06-29 12:00:00')
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: final_week_start,
        first_captain_reply_at: final_week_start + 1.minute,
        resolved_at: final_week_start + 1.hour
      )

      outside_window_start = Time.zone.parse('2025-05-31 12:00:00')
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: outside_window_start,
        first_captain_reply_at: outside_window_start + 1.minute,
        resolved_at: outside_window_start + 1.hour
      )

      other_assistant = create(:captain_assistant, account: account)
      other_assistant_start = Time.zone.parse('2025-06-02 12:00:00')
      create(
        :conversation_outcome,
        account: account,
        assistant: other_assistant,
        inbox: inbox,
        started_at: other_assistant_start,
        first_captain_reply_at: other_assistant_start + 1.minute,
        resolved_at: other_assistant_start + 1.hour
      )
    end

    it 'counts handled and Captain-resolved outcomes in their demand week' do
      bucket_counts = metrics[:buckets].map { |bucket| bucket.values_at(:conversations_handled, :resolved_by_captain) }

      expect(bucket_counts).to eq([
                                    [1, 1],
                                    [1, 0],
                                    [0, 0],
                                    [1, 0],
                                    [1, 1]
                                  ])
    end

    it 'computes every bucket in one outcome query' do
      queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        queries << payload[:sql] if payload[:sql].include?('FROM "conversation_outcomes"') && !payload[:cached]
      end

      ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') { metrics }

      expect(queries.size).to eq(1)
    end
  end

  it 'anchors calendar buckets to the viewer timezone' do
    started_at = Time.zone.parse('2025-05-31 19:00:00')
    create(
      :conversation_outcome,
      account: account,
      assistant: assistant,
      inbox: inbox,
      started_at: started_at,
      first_captain_reply_at: started_at + 1.minute,
      resolved_at: started_at + 1.hour
    )

    timezone_metrics = described_class.new(assistant, range, 5.5).metrics

    expect(timezone_metrics[:buckets].first).to include(
      starts_on: Date.new(2025, 6, 1),
      conversations_handled: 1,
      resolved_by_captain: 1
    )
  end
end
