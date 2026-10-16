require 'rails_helper'

RSpec.describe CopilotRun do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) do
    described_class.create!(account: account, user: user, copilot_thread: thread, copilot_message: message, kind: :turn)
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
