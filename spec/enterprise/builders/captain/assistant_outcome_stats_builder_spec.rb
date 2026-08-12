require 'rails_helper'

RSpec.describe Captain::AssistantOutcomeStatsBuilder do
  subject(:metrics) { described_class.new(assistant, '30').metrics }

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  context 'with no outcomes' do
    it 'returns zeroed metrics' do
      expect(metrics[:eligible_conversations]).to eq(current: 0, previous: 0, trend: 0)
      expect(metrics[:coverage_rate][:current]).to eq(0)
      expect(metrics[:durable_resolution_rate][:current]).to eq(0)
      expect(metrics[:handoff_reasons]).to eq({})
    end
  end

  context 'with demand in both windows' do
    before do
      demand_start = 20.days.ago.change(usec: 0)
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: demand_start,
        first_captain_reply_at: demand_start + 30.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 100.seconds,
        csat_rating: 5
      )

      demand_start = 20.days.ago.change(usec: 0)
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: demand_start,
        first_captain_reply_at: demand_start + 60.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 200.seconds,
        ended_at: demand_start + 1.day
      )

      demand_start = 6.days.ago.change(usec: 0)
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: demand_start,
        first_captain_reply_at: demand_start + 90.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 300.seconds
      )

      demand_start = 10.days.ago.change(usec: 0)
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: demand_start,
        first_captain_reply_at: demand_start + 120.seconds,
        captain_reply_count: 2,
        handoff_at: demand_start + 150.seconds,
        handoff_reason_category: 'missing_knowledge',
        first_human_reply_at: demand_start + 250.seconds,
        resolved_at: demand_start + 400.seconds,
        csat_rating: 4
      )

      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: 5.days.ago,
        handoff_at: 5.days.ago,
        handoff_reason_category: 'usage_limit'
      )
      create(:conversation_outcome, account: account, assistant: assistant, inbox: inbox, started_at: 4.days.ago)

      demand_start = 45.days.ago.change(usec: 0)
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: demand_start,
        first_captain_reply_at: demand_start + 45.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 500.seconds
      )
    end

    it 'computes the outcome funnel and comparison trends' do
      expect(metrics[:eligible_conversations]).to eq(current: 6, previous: 1, trend: 500.0)
      expect(metrics[:coverage_rate]).to include(current: 66.7, previous: 100.0)
      expect(metrics[:autonomous_resolutions][:current]).to eq(3)
      expect(metrics[:autonomous_resolution_rate][:current]).to eq(50.0)
      expect(metrics[:assisted_resolutions][:current]).to eq(1)
      expect(metrics[:durable_resolution_rate][:current]).to eq(50.0)
    end

    it 'computes CSAT and median durations from outcome facts' do
      expect(metrics[:csat_score][:current]).to eq(4.5)
      expect(metrics[:median_first_response_seconds][:current]).to eq(75)
      expect(metrics[:median_resolution_seconds][:current]).to eq(250)
    end

    it 'returns the current-window handoff reason distribution' do
      expect(metrics[:handoff_reasons]).to eq('missing_knowledge' => 1, 'usage_limit' => 1)
    end
  end

  it 'counts an unclassified handoff as Captain involvement' do
    create(
      :conversation_outcome,
      account: account,
      assistant: assistant,
      inbox: inbox,
      started_at: 1.day.ago,
      handoff_at: 1.day.ago
    )

    expect(metrics[:coverage_rate][:current]).to eq(100.0)
  end

  it 'does not count an episode in both adjacent day windows' do
    travel_to Time.zone.parse('2026-08-12 12:00:00') do
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: 7.days.ago
      )

      boundary_metrics = described_class.new(assistant, '7').metrics

      expect(boundary_metrics[:eligible_conversations]).to include(current: 1, previous: 0)
    end
  end

  it 'compares Captain CSAT with conversations where Captain never participated' do
    human_conversation = create(:conversation, account: account, inbox: inbox)
    human_survey = create(:message, account: account, inbox: inbox, conversation: human_conversation, content_type: :input_csat)
    create(
      :csat_survey_response,
      account: account,
      conversation: human_conversation,
      contact: human_conversation.contact,
      message: human_survey,
      rating: 3,
      created_at: 5.days.ago
    )

    involved_outcome = create(
      :conversation_outcome,
      account: account,
      assistant: assistant,
      inbox: inbox,
      started_at: 5.days.ago,
      first_captain_reply_at: 5.days.ago,
      csat_rating: 5
    )
    involved_survey = create(
      :message,
      account: account,
      inbox: inbox,
      conversation: involved_outcome.conversation,
      content_type: :input_csat
    )
    create(
      :csat_survey_response,
      account: account,
      conversation: involved_outcome.conversation,
      contact: involved_outcome.conversation.contact,
      message: involved_survey,
      rating: 5,
      created_at: 5.days.ago
    )

    expect(metrics[:human_only_csat_score][:current]).to eq(3.0)
  end
end
