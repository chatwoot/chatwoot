require 'rails_helper'

RSpec.describe Captain::AssistantOutcomeStatsBuilder do
  subject(:metrics) { described_class.new(assistant, '30').metrics }

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  def create_outcome(created_at:, **attributes)
    conversation = create(:conversation, account: account, inbox: inbox)
    create(
      :captain_conversation_outcome,
      account: account,
      assistant: assistant,
      conversation: conversation,
      inbox: inbox,
      created_at: created_at,
      **attributes
    )
  end

  context 'with no outcomes' do
    it 'returns zeroed metrics' do
      expect(metrics[:autonomous_resolutions]).to eq(current: 0, previous: 0, trend: 0)
      expect(metrics[:durable_resolution_rate][:current]).to eq(0)
      expect(metrics[:handoff_reasons]).to eq({})
    end
  end

  context 'with outcome activity across the windows' do
    before do
      # Autonomous and durable: resolved 20 days ago, never reopened.
      demand_start = 20.days.ago - 100.seconds
      create_outcome(
        created_at: demand_start,
        first_captain_reply_at: demand_start + 30.seconds,
        last_captain_reply_at: demand_start + 30.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 100.seconds,
        csat_rating: 5,
        csat_received_at: 19.days.ago
      )

      # Autonomous but reopened after resolution: assessable, not durable.
      demand_start = 15.days.ago - 200.seconds
      create_outcome(
        created_at: demand_start,
        first_captain_reply_at: demand_start + 60.seconds,
        last_captain_reply_at: demand_start + 60.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 200.seconds,
        last_reopened_at: 14.days.ago,
        reopen_count: 1
      )

      # Demand started before the window, resolved inside it: counts via the
      # resolution anchor. Resolved too recently to judge durability.
      create_outcome(
        created_at: 40.days.ago,
        first_captain_reply_at: 40.days.ago + 90.seconds,
        last_captain_reply_at: 40.days.ago + 90.seconds,
        captain_reply_count: 1,
        resolved_at: 5.days.ago
      )

      # Handed off, human closed it out: involved but never autonomous.
      demand_start = 8.days.ago - 400.seconds
      create_outcome(
        created_at: demand_start,
        first_captain_reply_at: demand_start + 120.seconds,
        last_captain_reply_at: demand_start + 120.seconds,
        captain_reply_count: 2,
        handoff_at: 10.days.ago,
        handoff_reason_category: 'missing_knowledge',
        first_human_reply_at: demand_start + 250.seconds,
        resolved_at: demand_start + 400.seconds,
        csat_rating: 4,
        csat_received_at: 7.days.ago
      )

      # Blocked by the usage limit: shows up only in the reason distribution.
      create_outcome(
        created_at: 5.days.ago,
        handoff_at: 5.days.ago,
        handoff_reason_category: 'usage_limit'
      )

      # Previous-window activity: replied and resolved 45 days ago.
      demand_start = 45.days.ago - 500.seconds
      create_outcome(
        created_at: demand_start,
        first_captain_reply_at: demand_start + 45.seconds,
        last_captain_reply_at: demand_start + 45.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 500.seconds
      )
    end

    it 'counts autonomous resolutions by when the resolution happened' do
      expect(metrics[:autonomous_resolutions]).to include(current: 3, previous: 1)
    end

    it 'computes durability only over resolutions old enough to judge' do
      expect(metrics[:durable_resolution_rate][:current]).to eq(50.0)
    end

    it 'computes the resolution-time median over involved resolutions in the window' do
      expect(metrics[:median_resolution_seconds][:current]).to eq(300)
    end

    it 'computes the first-response median over replies in the window' do
      expect(metrics[:median_first_response_seconds][:current]).to eq(60)
      expect(metrics[:median_first_response_seconds][:previous]).to eq(67)
    end

    it 'averages CSAT over ratings received in the window' do
      expect(metrics[:csat_score][:current]).to eq(4.5)
    end

    it 'returns the handoff reason distribution for handoffs in the window' do
      expect(metrics[:handoff_reasons]).to eq('missing_knowledge' => 1, 'usage_limit' => 1)
    end

    it 'returns a conserving resolution flow for the conversations worked in the window' do
      # Still-open cohort member: replied in the window, no terminal state yet.
      create_outcome(
        created_at: 3.days.ago,
        first_captain_reply_at: 3.days.ago,
        last_captain_reply_at: 3.days.ago,
        captain_reply_count: 1
      )

      flow = metrics[:flow]

      expect(flow[:handled]).to eq(4)
      expect(flow[:captain_resolved]).to eq(total: 2, stayed_closed: 1, reopened: 1)
      expect(flow[:handed_to_team]).to eq(total: 1, reasons: { 'missing_knowledge' => 1 })
      expect(flow[:still_open]).to eq(1)
      expect(flow[:handled]).to eq(
        flow[:captain_resolved][:total] + flow[:handed_to_team][:total] + flow[:team_resolved] + flow[:still_open]
      )
    end
  end

  describe 'human-only CSAT baseline' do
    it 'averages CSAT for conversations without Captain involvement' do
      create(:csat_survey_response, account: account, rating: 3, created_at: 5.days.ago)

      involved = create_outcome(
        created_at: 5.days.ago,
        first_captain_reply_at: 5.days.ago,
        last_captain_reply_at: 5.days.ago,
        csat_rating: 5,
        csat_received_at: 5.days.ago
      )
      create(
        :csat_survey_response,
        account: account,
        conversation: involved.conversation,
        contact: involved.conversation.contact,
        rating: 5,
        created_at: 5.days.ago
      )

      expect(metrics[:human_only_csat_score][:current]).to eq(3.0)
    end
  end
end
