require 'rails_helper'

RSpec.describe CopilotRun do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) { CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message) }
  let(:tool_call) { turn.tool_calls.create!(call_id: 'review-1', name: 'review_conversations') }
  let(:collection) do
    CopilotRun::Collection.create!(account: account, user: user, copilot_thread: thread, status: :completed,
                                   context: { resource: 'conversations', selected_ids: [1, 2, 3, 4], as_of: Time.current.iso8601 })
  end
  let(:review) do
    CopilotRun::Review.create!(account: account, user: user, copilot_thread: thread, copilot_tool_call: tool_call, source_run: collection,
                               context: { criteria: 'Is this about billing?', turn_start: 0, turn_limit: 3 })
  end

  describe 'validations' do
    it 'refuses a status that belongs to another kind of run' do
      expect(review.update(status: :awaiting_background_run)).to be false
      expect(collection.update(status: :running)).to be false
      expect(turn.update(status: :awaiting_approval)).to be false
    end

    it 'requires the details each kind of run reads' do
      review_without_criteria = CopilotRun::Review.new(account: account, user: user, copilot_thread: thread, source_run: collection,
                                                       context: { turn_start: 0 })
      collection_without_date = CopilotRun::Collection.new(account: account, user: user, copilot_thread: thread, status: :completed,
                                                           context: { resource: 'conversations' })
      action_without_change = CopilotRun::Action.new(account: account, user: user, copilot_thread: thread, status: :awaiting_approval)

      expect(review_without_criteria).not_to be_valid
      expect(review_without_criteria.errors.attribute_names).to contain_exactly(:criteria, :turn_limit)
      expect(collection_without_date).not_to be_valid
      expect(collection_without_date.errors.attribute_names).to contain_exactly(:as_of)
      expect(action_without_change).not_to be_valid
      expect(action_without_change.errors.attribute_names).to contain_exactly(:action, :target_ids)
    end
  end

  describe '#review_budget!' do
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
      review.update!(turn_start: 2)
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
