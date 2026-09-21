require 'rails_helper'

RSpec.describe Copilot::V2::ChatService do
  it 'replays every native tool-call ID and stops after a single provider response' do
    account = create(:account)
    user = create(:user, account: account)
    thread = CopilotThread.create!(account: account, user: user, engine: :v2, title: 'Test')
    trigger = thread.copilot_messages.create!(message_type: :user, message: { content: 'Show my queue' })
    run = CopilotRun.create!(copilot_thread: thread, triggering_message: trigger, checkpoint: { 'transcript' => [
                               { 'role' => 'user', 'content' => 'Show my queue' },
                               { 'role' => 'assistant', 'content' => '', 'tool_calls' => [
                                 { 'id' => 'first', 'name' => 'resource_catalog', 'arguments' => {} },
                                 { 'id' => 'second', 'name' => 'resource_catalog', 'arguments' => {} }
                               ] },
                               { 'role' => 'tool', 'tool_call_id' => 'first', 'content' => '{}' },
                               { 'role' => 'tool', 'tool_call_id' => 'second', 'content' => '{}' }
                             ] })
    service = described_class.new(account: account, user: user, thread: thread)
    allow(RubyLLM.config).to receive(:openai_api_key).and_return('test-key')
    llm = service.chat
    allow(service).to receive(:chat).and_return(llm)
    provider = llm.instance_variable_get(:@provider)
    response = RubyLLM::Message.new(role: :assistant, content: '', tool_calls: {
                                      'third' => RubyLLM::ToolCall.new(id: 'third', name: 'resource_catalog', arguments: {}),
                                      'fourth' => RubyLLM::ToolCall.new(id: 'fourth', name: 'resource_catalog', arguments: {})
                                    })
    allow(provider).to receive(:complete).and_return(response)
    expect(service.coordinate(run)).to eq(response)
    expect(provider).to have_received(:complete).once
    expect(llm.messages.find(&:tool_call?).tool_calls.keys).to eq(%w[first second])
    expect(llm.messages.select(&:tool_result?).map(&:tool_call_id)).to eq(%w[first second])
    expect(described_class.serialize(response)['tool_calls'].pluck('id')).to eq(%w[third fourth])
  end
end
