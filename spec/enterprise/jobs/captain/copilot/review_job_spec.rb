require 'rails_helper'

RSpec.describe Captain::Copilot::ReviewJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversations) { create_list(:conversation, 3, account: account, inbox: inbox) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) { CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message) }
  let(:collection) do
    CopilotRun::Collection.create!(account: account, user: user, copilot_thread: thread, status: :completed,
                                   context: { resource: 'conversations', selected_ids: conversations.map(&:id), filters: {},
                                              as_of: 1.minute.from_now.iso8601 })
  end
  let(:review) do
    CopilotRun::Review.create!(account: account, user: user, copilot_thread: thread, source_run: collection, status: :queued,
                               copilot_tool_call: turn.tool_calls.create!(call_id: 'review-1', name: 'review_conversations'),
                               context: { request: 'Which ones ask about billing?', criteria: 'Asks about billing', turn_start: 0,
                                          turn_limit: 10, turn_start_matched: 0, turn_start_failed: 0 })
  end
  let(:service) { instance_double(Captain::Copilot::ReviewService) }
  let(:verdict) do
    { status: :reviewed, matched: true, category: 'Billing', reason: 'Asks about an invoice', evidence_message_ids: [],
      reviewed_message_ids: [], history_truncated: false }
  end

  before do
    account.enable_features!('copilot_workflows')
    allow(Captain::Copilot::ReviewService).to receive(:new).and_return(service)
  end

  it 'hands each conversation of a batch to its own job, and the last one hands the run back for the next batch' do
    failing = conversations.first
    allow(service).to receive(:review) do |conversation, **|
      raise Faraday::TimeoutError, 'timed out' if conversation == failing

      verdict
    end

    described_class.perform_now(review.id)

    expect(review.reload).to be_reviewing
    expect(review.pending_ids).to match_array(conversations.map(&:id))
    conversations.each { |conversation| Captain::Copilot::ReviewConversationJob.perform_now(review.id, conversation.id) }

    findings = review.findings.index_by(&:conversation_id)
    expect(conversations.drop(1).map { |conversation| findings[conversation.id].status }).to eq(%w[reviewed reviewed])
    expect(findings[failing.id]).to have_attributes(status: 'awaiting_retry', error: 'Review failed (Faraday::TimeoutError)')
    expect(review.reload).to be_queued
    expect(described_class).to have_been_enqueued.with(review.id)
  end

  it 'completes a review that finished every conversation, even when workflows were switched off during the last batch' do
    allow(service).to receive(:review).and_return(verdict)
    described_class.perform_now(review.id)
    conversations.each { |conversation| Captain::Copilot::ReviewConversationJob.perform_now(review.id, conversation.id) }
    account.disable_features!('copilot_workflows')

    described_class.perform_now(review.id)

    expect(review.reload).to have_attributes(status: 'completed', error: nil)
  end

  it 'saves nothing from a repeated job' do
    allow(service).to receive(:review).and_return(verdict)
    described_class.perform_now(review.id)
    Captain::Copilot::ReviewConversationJob.perform_now(review.id, conversations.first.id)

    Captain::Copilot::ReviewConversationJob.perform_now(review.id, conversations.first.id)

    expect(service).to have_received(:review).once
    expect(review.reload.pending_ids).to match_array(conversations.drop(1).map(&:id))
  end

  it 'reviews a few conversations at once, and the rest of the screened batch in the next round' do
    stub_const("#{described_class}::PARALLEL_REVIEWS", 2)
    allow(service).to receive(:review).and_return(verdict)

    described_class.perform_now(review.id)
    expect(review.reload.pending_ids).to eq(conversations.first(2).map(&:id))
    review.pending_ids.each { |id| Captain::Copilot::ReviewConversationJob.perform_now(review.id, id) }
    described_class.perform_now(review.id)

    expect(review.reload.pending_ids).to eq([conversations.last.id])
  end

  it 'records a conversation deleted while its job waited, without failing the review' do
    allow(service).to receive(:review).and_return(verdict)
    described_class.perform_now(review.id)
    conversations.first.destroy!

    Captain::Copilot::ReviewConversationJob.perform_now(review.id, conversations.first.id)

    expect(review.findings.find_by(conversation_id: conversations.first.id)).to have_attributes(error: 'Conversation is no longer accessible')
  end

  it 'takes back a batch whose jobs stopped coming back, but not one whose jobs may still be waiting in the queue' do
    allow(service).to receive(:review).and_return(verdict)
    described_class.perform_now(review.id)

    travel(10.minutes) { Captain::Copilot::RecoverRunsJob.perform_now }
    expect(review.reload).to be_reviewing

    travel(31.minutes) { Captain::Copilot::RecoverRunsJob.perform_now }
    expect(review.reload).to have_attributes(status: 'queued', pending_ids: [])
    expect(described_class).to have_been_enqueued.with(review.id)
  end
end
