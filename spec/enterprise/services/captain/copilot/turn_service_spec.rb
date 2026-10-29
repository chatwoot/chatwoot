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
  it 'writes one plain line per step, marks a failed step, and adds a warning line for a failed tool without a step line' do
    service.send(:start_tool_call, RubyLLM::ToolCall.new(id: 'call-1', name: 'search_contacts', arguments: {}))
    service.send(:finish_tool_call, { contacts: [] })
    service.send(:start_tool_call, RubyLLM::ToolCall.new(id: 'call-2', name: 'get_contact', arguments: { contact_id: 1 }))
    service.send(:finish_tool_call, { error: 'Contact not found' })
    service.send(:start_tool_call, RubyLLM::ToolCall.new(id: 'call-3', name: 'act', arguments: {}))
    service.send(:finish_tool_call, { error: 'There are no records to change' })

    expect(steps).to eq([{ 'content' => 'Searching contacts' }, { 'content' => 'Looking up a contact', 'status' => 'failed' },
                         { 'content' => "Couldn't finish this step", 'status' => 'failed' }])
  end

  it 'sends numbers no tool result supports back to the model once, as its own check' do
    run.tool_calls.create!(call_id: 'call-1', name: 'get_data', status: :completed, result: { groups: [{ value: 10 }, { value: 20 }] })
    draft = RubyLLM::Message.new(role: :assistant, content: { content: 'Email takes 10 hours, chat 20, and 15 on average.' }.to_json)
    llm = instance_double(RubyLLM::Chat, messages: [draft], add_message: nil)
    service.instance_variable_set(:@transcript, instance_double(Captain::Copilot::TurnTranscript, save: nil))

    expect(service.send(:revise_numbers?, llm)).to be(true)
    expect(llm).to have_received(:add_message).with(role: :user, content: include('- 15 in: Email takes 10 hours, chat 20, and 15 on average.'))
    expect(service.send(:revise_numbers?, llm)).to be(false)
  end

  it 'keeps the links a tool returned and removes the links it made up' do
    guide = 'https://help.example.com/hc/docs/articles/refunds?lang=en&ref=copilot'
    run.tool_calls.create!(call_id: 'call-1', name: 'get_data', status: :completed,
                           result: { rows: [{ url: '/app/accounts/1/conversations/5' }], article: guide })
    answer = "See [#5](/app/accounts/1/conversations/5), [the guide](#{guide}) and [pricing](https://example.com/pricing)."
    llm = instance_double(RubyLLM::Chat, messages: [RubyLLM::Message.new(role: :assistant, content: { content: answer }.to_json)])

    service.send(:finish, llm)

    expect(thread.copilot_messages.assistant.last.message['content'])
      .to eq("See [#5](/app/accounts/1/conversations/5), [the guide](#{guide}) and pricing.")
  end

  it 'writes no line for a review, which shows its own card, or while the turn waits for it' do
    service.send(:start_tool_call, RubyLLM::ToolCall.new(id: 'call-1', name: 'review_conversations', arguments: {}))
    service.send(:wait_for_background_run)

    expect(steps).to be_empty
    expect(run.reload).to be_awaiting_background_run
  end
end
