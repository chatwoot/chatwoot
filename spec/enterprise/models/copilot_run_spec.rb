require 'rails_helper'

RSpec.describe CopilotRun do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) do
    described_class.create!(account: account, user: user, copilot_thread: thread, copilot_message: message, kind: :turn)
  end

  describe '#review_budget!' do
    let(:collection) do
      described_class.create!(account: account, user: user, copilot_thread: thread, kind: :collection, status: :completed,
                              context: { resource: 'conversations', selected_ids: [1, 2, 3, 4], as_of: Time.current.iso8601 })
    end
    let(:review) do
      tool_call = turn.tool_calls.create!(call_id: 'review-1', name: 'review_conversations')
      described_class.create!(account: account, user: user, copilot_thread: thread, copilot_tool_call: tool_call, source_run: collection,
                              kind: :review, context: { turn_start: 0, turn_limit: 3 })
    end

    before { stub_const('CopilotRun::CONVERSATIONS_PER_TURN', 3) }

    it 'leaves a later review in the same turn only what is left, then refuses more' do
      review.findings.create!(conversation_id: 1, status: :screened_out)
      review.findings.create!(conversation_id: 2, status: :reviewed)
      review.findings.create!(conversation_id: 3, status: :awaiting_review)

      expect(turn.review_budget!).to eq(1)

      review.findings.find_by!(conversation_id: 3).update!(status: :failed)
      expect { turn.review_budget! }.to raise_error(ArgumentError, /already reviewed 3 conversations/)
    end

    it 'counts a continued review only from where this turn took it' do
      review.update!(context: review.context.merge('turn_start' => 2))
      [1, 2, 3].each { |id| review.findings.create!(conversation_id: id, status: :screened_out) }

      expect(turn.review_budget!).to eq(2)
    end
  end

  describe '#record_cost!' do
    it 'adds provider costs to the user turn' do
      turn.record_cost!(0.0123456789)
      turn.record_cost!(0.0000000001)

      expect(turn.reload.total_cost_usd).to eq(BigDecimal('0.012345679'))
      expect(turn.cost_complete).to be true
    end

    it 'records a background review cost on the turn that started it' do
      tool_call = turn.tool_calls.create!(call_id: 'review-1', name: 'review_conversations')
      review = described_class.create!(account: account, user: user, copilot_thread: thread, copilot_tool_call: tool_call, kind: :review)

      review.record_cost!(0.05)

      expect(turn.reload.total_cost_usd).to eq(BigDecimal('0.05'))
      expect(review.reload.total_cost_usd).to be_zero
    end

    it 'marks the total incomplete when a provider does not report cost' do
      turn.record_cost!(nil)

      expect(turn.reload.cost_complete).to be false
      expect(turn.total_cost_usd).to be_zero
    end
  end
end
