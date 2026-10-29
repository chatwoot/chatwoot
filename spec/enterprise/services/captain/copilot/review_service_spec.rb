require 'rails_helper'

RSpec.describe Captain::Copilot::ReviewService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) { CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message) }
  let(:collection) do
    CopilotRun::Collection.create!(account: account, user: user, copilot_thread: thread, status: :completed,
                                   context: { resource: 'conversations', selected_ids: [], filters: {}, as_of: 1.minute.from_now.iso8601 })
  end
  let(:review) do
    CopilotRun::Review.create!(account: account, user: user, copilot_thread: thread, source_run: collection, status: :queued,
                               copilot_tool_call: turn.tool_calls.create!(call_id: 'review-1', name: 'review_conversations'),
                               context: { request: 'Why were these rated low?', criteria: 'Why the rating was low', turn_start: 0,
                                          turn_limit: 10, turn_start_matched: 0, turn_start_failed: 0 })
  end
  let(:service) { described_class.new(review) }
  let(:row) do
    { 'matched' => true, 'needs_more_history' => true, 'category' => 'No reply', 'reason' => 'Nobody answered',
      'evidence_message_ids' => [1] }
  end

  before do
    InstallationConfig.find_or_create_by(name: 'CAPTAIN_OPEN_AI_API_KEY') { |config| config.value = 'test-key' }
  end

  it 'keeps the result when the reviewer saw the whole conversation but asked for more history' do
    whole = { history_truncated: false, messages: [{ id: 1, content_truncated: false }] }

    expect(service.send(:parse_result, row, whole, true)).to include(status: :reviewed, matched: true, category: 'No reply')
  end

  it 'reads more history when messages were left out' do
    cut = { history_truncated: true, messages: [{ id: 1, content_truncated: false }] }

    expect(service.send(:parse_result, row, cut, false)).to include(status: :needs_more_history, matched: false)
  end
end
