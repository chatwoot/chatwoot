require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::ReviewConversationsService do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: admin) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) { CopilotRun::Turn.create!(account: account, user: admin, copilot_thread: thread, copilot_message: message) }
  let(:collection) do
    CopilotRun::Collection.create!(account: account, user: admin, copilot_thread: thread, status: :completed,
                                   context: { resource: 'conversations', selected_ids: [1, 2], filters: {}, as_of: Time.current.iso8601 })
  end
  let(:tool) do
    described_class.new(thread.assistant, user: admin, run: turn, lease_token: turn.claim)
                   .tap { |review_tool| review_tool.tool_call = turn.tool_calls.create!(call_id: 'review-1', name: 'review_conversations') }
  end

  it 'gives every review of the collection the same reference' do
    tool.execute(collection_id: collection.id, criteria: 'Is the question answered by an article?', reference: 'Billing FAQ: plans and prices')

    prompt = JSON.parse(Captain::Copilot::ReviewService.new(CopilotRun::Review.last).send(:review_prompt, {}))
    expect(prompt).to include('reference' => 'Billing FAQ: plans and prices')
  end

  it 'rejects an empty reference' do
    expect { tool.execute(collection_id: collection.id, criteria: 'Is the question answered by an article?', reference: '') }
      .to raise_error(ActiveRecord::RecordInvalid, /Reference must be a nonempty string/)
  end
end
