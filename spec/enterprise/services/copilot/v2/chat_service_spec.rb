require 'rails_helper'

RSpec.describe Copilot::V2::ChatService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user, engine: :v2, assistant: nil) }
  let(:llm_chat) { instance_double(RubyLLM::Chat) }
  let(:response) { instance_double(RubyLLM::Message, content: 'Hello there') }
  let(:service) { described_class.new(account: account, user: user, thread: thread) }

  before do
    allow(Llm::Config).to receive(:initialize!)
    allow(RubyLLM).to receive(:chat).and_return(llm_chat)
    allow(llm_chat).to receive_messages(with_temperature: llm_chat, with_instructions: llm_chat, add_message: llm_chat, ask: response)
  end

  it 'uses the existing copilot model route without Captain task inheritance' do
    expect(Llm::FeatureRouter).to receive(:resolve).with(feature: 'copilot', account: account).and_call_original
    expect(service.class.superclass.name).to eq('Llm::BaseAiService')
    expect(service.class.ancestors.map(&:name)).not_to include('Captain::BaseTaskService')
  end

  it 'sends chat history once and saves a compatible assistant message without registering tools' do
    create(:captain_copilot_message, copilot_thread: thread, message: { content: 'First question' })
    create(:captain_copilot_message, copilot_thread: thread, message_type: :assistant, message: { content: 'First answer' })
    create(:captain_copilot_message, copilot_thread: thread, message: { content: 'Follow up' })

    expect(llm_chat).to receive(:add_message).with(role: :user, content: 'First question')
    expect(llm_chat).to receive(:add_message).with(role: :assistant, content: 'First answer')
    expect(llm_chat).to receive(:ask).with('Follow up').once
    expect(llm_chat).not_to receive(:with_tool)
    expect(account).to receive(:increment_response_usage).once

    expect { service.generate_response }.to change { thread.copilot_messages.assistant.count }.by(1)
    expect(thread.copilot_messages.last.message).to eq('content' => 'Hello there')
  end
end
