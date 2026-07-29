require 'rails_helper'

RSpec.describe Captain::AssistantOutcomeStatsBuilder do
  subject(:metrics) { described_class.new(assistant, '30').metrics }

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  def create_outcome(started_at:, **attributes)
    conversation = create(:conversation, account: account, inbox: inbox)
    create(
      :conversation_outcome,
      account: account,
      assistant: assistant,
      conversation: conversation,
      inbox: inbox,
      started_at: started_at,
      **attributes
    )
  end

  context 'with no outcomes' do
    it 'returns zeroed metrics' do
      expect(metrics[:eligible_conversations]).to eq(current: 0, previous: 0, trend: 0)
      expect(metrics[:coverage_rate][:current]).to eq(0)
      expect(metrics[:durable_resolution_rate][:current]).to eq(0)
      expect(metrics[:handoff_reasons]).to eq({})
    end
  end

  context 'with a demand cohort in the current window' do
    before do
      # Autonomous and durable: resolved 20 days ago, never reopened.
      demand_start = 20.days.ago
      create_outcome(
        started_at: demand_start,
        first_captain_reply_at: demand_start + 30.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 100.seconds,
        csat_rating: 5
      )

      # Autonomous but followed by a new episode within seven days: assessable, not durable.
      demand_start = 20.days.ago
      create_outcome(
        started_at: demand_start,
        first_captain_reply_at: demand_start + 60.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 200.seconds,
        ended_at: demand_start + 200.seconds + 1.day
      )

      # Autonomous but resolved too recently to judge durability.
      demand_start = 6.days.ago
      create_outcome(
        started_at: demand_start,
        first_captain_reply_at: demand_start + 90.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 300.seconds
      )

      # Assisted: Captain replied, then handed off, human closed it out.
      demand_start = 10.days.ago
      create_outcome(
        started_at: demand_start,
        first_captain_reply_at: demand_start + 120.seconds,
        captain_reply_count: 2,
        handoff_at: demand_start + 150.seconds,
        handoff_reason_category: 'missing_knowledge',
        first_human_reply_at: demand_start + 250.seconds,
        resolved_at: demand_start + 400.seconds,
        csat_rating: 4
      )

      # Blocked by the usage limit: eligible demand, not involvement.
      create_outcome(
        started_at: 5.days.ago,
        handoff_at: 5.days.ago,
        handoff_reason_category: 'usage_limit'
      )

      # Demand Captain never touched.
      create_outcome(started_at: 4.days.ago)

      # Previous-window demand: one involved, autonomous resolution.
      demand_start = 45.days.ago
      create_outcome(
        started_at: demand_start,
        first_captain_reply_at: demand_start + 45.seconds,
        captain_reply_count: 1,
        resolved_at: demand_start + 500.seconds
      )
    end

    it 'counts eligible demand per window with a trend' do
      expect(metrics[:eligible_conversations]).to eq(current: 6, previous: 1, trend: 500.0)
    end

    it 'computes coverage as involved over eligible, excluding usage-limit handoffs' do
      expect(metrics[:coverage_rate][:current]).to eq(66.7)
      expect(metrics[:coverage_rate][:previous]).to eq(100.0)
    end

    it 'classifies autonomous and assisted resolutions' do
      expect(metrics[:autonomous_resolutions][:current]).to eq(3)
      expect(metrics[:autonomous_resolution_rate][:current]).to eq(50.0)
      expect(metrics[:assisted_resolutions][:current]).to eq(1)
    end

    it 'computes durability only over resolutions old enough to judge' do
      expect(metrics[:durable_resolution_rate][:current]).to eq(50.0)
    end

    it 'averages CSAT over involved conversations' do
      expect(metrics[:csat_score][:current]).to eq(4.5)
    end

    it 'computes median first response and resolution times from the row timestamps' do
      expect(metrics[:median_first_response_seconds][:current]).to eq(75)
      expect(metrics[:median_resolution_seconds][:current]).to eq(250)
    end

    it 'returns the current-window handoff reason distribution' do
      expect(metrics[:handoff_reasons]).to eq('missing_knowledge' => 1, 'usage_limit' => 1)
    end
  end

  describe 'human-only CSAT baseline' do
    it 'averages CSAT for conversations without Captain involvement' do
      create(:csat_survey_response, account: account, rating: 3, created_at: 5.days.ago)

      involved = create_outcome(started_at: 5.days.ago, first_captain_reply_at: 5.days.ago, csat_rating: 5)
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
