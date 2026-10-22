require 'rails_helper'

RSpec.describe Captain::Copilot::TurnService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:run) { CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message) }
  let(:service) { described_class.new(run, run.claim) }
  let(:steps) { thread.copilot_messages.assistant_thinking.order(:id).map { |step| step.message.slice('content', 'status') } }

  before do
    InstallationConfig.find_or_create_by(name: 'CAPTAIN_OPEN_AI_API_KEY') { |config| config.value = 'test-key' }
  end

  # RubyLLM calls these around every tool call.
  it 'writes one plain line per step, and a warning line only when a step fails' do
    service.send(:start_tool_call, RubyLLM::ToolCall.new(id: 'call-1', name: 'search_contacts', arguments: {}))
    service.send(:finish_tool_call, { contacts: [] })
    service.send(:start_tool_call, RubyLLM::ToolCall.new(id: 'call-2', name: 'get_contact', arguments: { contact_id: 1 }))
    service.send(:finish_tool_call, { error: 'Contact not found' })

    expect(steps).to eq([{ 'content' => 'Searching contacts' }, { 'content' => 'Looking up a contact' },
                         { 'content' => "Couldn't finish this step", 'status' => 'failed' }])
  end

  it 'writes no line for a review, which shows its own card, or while the turn waits for it' do
    service.send(:start_tool_call, RubyLLM::ToolCall.new(id: 'call-1', name: 'review_conversations', arguments: {}))
    service.send(:wait_for_background_run)

    expect(steps).to be_empty
    expect(run.reload).to be_awaiting_background_run
  end
end
