require 'rails_helper'

RSpec.describe Captain::AssistantResolutionFlowBuilder do
  subject(:resolution_flow) { described_class.new(assistant, '30').build }

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  context 'with no outcomes' do
    it 'returns an empty flow with stable nodes and links' do
      expect(resolution_flow).to eq(
        sankey: {
          nodes: [
            { id: :conversations_handled, count: 0 },
            { id: :resolved_by_captain, count: 0 },
            { id: :handed_off, count: 0 },
            { id: :closed_with_team, count: 0 },
            { id: :reopened_within_7_days, count: 0 },
            { id: :stayed_closed, count: 0 }
          ],
          links: [
            { source: :conversations_handled, target: :resolved_by_captain, value: 0 },
            { source: :conversations_handled, target: :handed_off, value: 0 },
            { source: :conversations_handled, target: :closed_with_team, value: 0 },
            { source: :resolved_by_captain, target: :reopened_within_7_days, value: 0 },
            { source: :resolved_by_captain, target: :stayed_closed, value: 0 }
          ]
        },
        handoff_distribution: []
      )
    end
  end

  context 'with handled outcomes in the current window' do
    before do
      now = Time.current.change(usec: 0)

      reopened_start = now - 20.days
      reopened_resolution = reopened_start + 1.hour
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: reopened_start,
        first_captain_reply_at: reopened_start + 1.minute,
        resolved_at: reopened_resolution,
        ended_at: reopened_resolution + 2.days
      )

      boundary_start = now - 15.days
      boundary_resolution = boundary_start + 1.hour
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: boundary_start,
        first_captain_reply_at: boundary_start + 1.minute,
        resolved_at: boundary_resolution,
        ended_at: boundary_resolution + 7.days
      )

      recent_start = now - 3.days
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: recent_start,
        first_captain_reply_at: recent_start + 1.minute,
        resolved_at: recent_start + 1.hour
      )

      assisted_start = now - 2.days
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: assisted_start,
        first_captain_reply_at: assisted_start + 1.minute,
        first_human_reply_at: assisted_start + 2.minutes,
        resolved_at: assisted_start + 1.hour
      )

      2.times do |index|
        started_at = now - (index + 4).days
        create(
          :conversation_outcome,
          account: account,
          assistant: assistant,
          inbox: inbox,
          started_at: started_at,
          first_captain_reply_at: started_at + 1.minute,
          handoff_at: started_at + 2.minutes,
          handoff_reason_category: 'customer_request'
        )
      end

      %w[missing_knowledge policy_restriction].each_with_index do |category, index|
        started_at = now - (index + 6).days
        create(
          :conversation_outcome,
          account: account,
          assistant: assistant,
          inbox: inbox,
          started_at: started_at,
          first_captain_reply_at: started_at + 1.minute,
          handoff_at: started_at + 2.minutes,
          handoff_reason_category: category
        )
      end

      unclassified_start = now - 8.days
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: unclassified_start,
        handoff_at: unclassified_start + 2.minutes
      )

      usage_limit_start = now - 9.days
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: usage_limit_start,
        handoff_at: usage_limit_start + 2.minutes,
        handoff_reason_category: 'usage_limit'
      )

      untouched_start = now - 10.days
      create(:conversation_outcome, account: account, assistant: assistant, inbox: inbox, started_at: untouched_start)

      outside_window_start = now - 45.days
      create(
        :conversation_outcome,
        account: account,
        assistant: assistant,
        inbox: inbox,
        started_at: outside_window_start,
        first_captain_reply_at: outside_window_start + 1.minute,
        resolved_at: outside_window_start + 1.hour
      )
    end

    it 'builds a balanced resolution flow' do
      expect(resolution_flow[:sankey]).to eq(
        nodes: [
          { id: :conversations_handled, count: 9 },
          { id: :resolved_by_captain, count: 3 },
          { id: :handed_off, count: 5 },
          { id: :closed_with_team, count: 1 },
          { id: :reopened_within_7_days, count: 1 },
          { id: :stayed_closed, count: 2 },
          { id: :handoff_reason_customer_request, count: 2 },
          { id: :handoff_reason_missing_knowledge, count: 1 },
          { id: :other_reasons, count: 2 }
        ],
        links: [
          { source: :conversations_handled, target: :resolved_by_captain, value: 3 },
          { source: :conversations_handled, target: :handed_off, value: 5 },
          { source: :conversations_handled, target: :closed_with_team, value: 1 },
          { source: :resolved_by_captain, target: :reopened_within_7_days, value: 1 },
          { source: :resolved_by_captain, target: :stayed_closed, value: 2 },
          { source: :handed_off, target: :handoff_reason_customer_request, value: 2 },
          { source: :handed_off, target: :handoff_reason_missing_knowledge, value: 1 },
          { source: :handed_off, target: :other_reasons, value: 2 }
        ]
      )
    end

    it 'returns every handoff reason with its share of involved handoffs' do
      expect(resolution_flow[:handoff_distribution]).to eq([
                                                             { category: 'customer_request', count: 2, percentage: 40.0 },
                                                             { category: 'missing_knowledge', count: 1, percentage: 20.0 },
                                                             { category: 'policy_restriction', count: 1, percentage: 20.0 },
                                                             { category: 'unclassified', count: 1, percentage: 20.0 }
                                                           ])
    end
  end
end
