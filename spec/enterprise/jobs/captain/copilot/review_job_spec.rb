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
  let(:service) { Captain::Copilot::ReviewService.new(review) }

  before do
    InstallationConfig.find_or_create_by(name: 'CAPTAIN_OPEN_AI_API_KEY') { |config| config.value = 'test-key' }
    account.enable_features!('copilot_workflows')
    conversations.each { |conversation| create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming) }
    allow(Captain::Copilot::ReviewService).to receive(:new).and_return(service)
  end

  it 'reviews the conversations of a batch at once and saves each result, failing only the one whose model call failed' do
    failing = conversations.first
    allow(service).to receive(:ask) do |request|
      raise Faraday::TimeoutError, 'timed out' if request[:conversation] == failing

      verdict = { matched: true, needs_more_history: false, category: 'Billing', reason: 'Asks about an invoice',
                  evidence_message_ids: [request[:evidence][:messages].first[:id]] }
      request.merge(content: verdict.to_json)
    end

    described_class.perform_now(review.id)

    findings = review.findings.index_by(&:conversation_id)
    expect(findings.values_at(*conversations.drop(1).map(&:id)).map { |finding| [finding.status, finding.error] })
      .to eq([['reviewed', nil], ['reviewed', nil]])
    expect(findings[failing.id]).to have_attributes(status: 'awaiting_retry', error: 'Review failed (Faraday::TimeoutError)')
  end
end
