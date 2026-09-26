# frozen_string_literal: true

require 'rails_helper'

# Runs the real Agents::Runner and RubyLLM::Chat against a scripted provider.
# RubyLLM keeps calling #complete after every tool result, so without the run
# guards these examples would loop until the worker is killed.
RSpec.describe Captain::Assistant::AgentRunnerService do
  subject(:service) { described_class.new(assistant: assistant, conversation: conversation, run_options: run_options) }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, status: :pending) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:run_options) { described_class::RunOptions.new }
  let(:faq_tool) { Captain::Tools::FaqLookupTool.new(assistant) }
  let(:tools) { [faq_tool] }
  let(:agent) { Agents::Agent.new(name: 'Assistant', instructions: 'Help the customer', model: 'fake-model', tools: tools) }
  let(:message_history) { [{ role: 'user', content: 'What services do you offer?' }] }
  let(:provider) { CaptainScriptedLlmProvider.new(tool_name: faq_tool.name) }

  before do
    scenarios = instance_double(Captain::Scenario, enabled: [])
    allow(assistant).to receive_messages(agent: agent, scenarios: scenarios)
    allow(RubyLLM::Models).to receive(:resolve).and_return([Struct.new(:id).new('fake-model'), provider])
    # The scripted provider replaces every RubyLLM model, so keep FAQ search away from embeddings.
    allow(Captain::AssistantResponse).to receive(:search).and_return(Captain::AssistantResponse.none)
  end

  context 'when the model keeps requesting the same tool with different arguments' do
    it 'stops the run at the tool call budget instead of looping forever' do
      allow(faq_tool).to receive(:perform).and_call_original

      response = service.generate_response(message_history: message_history)

      expect(faq_tool).to have_received(:perform).exactly(Captain::Tools::RunGuard::MAX_TOOL_CALLS_PER_RUN).times
      expect(provider.completions).to eq(Captain::Tools::RunGuard::MAX_TOOL_CALLS_PER_RUN + 1)
      expect(response).to include(
        'response' => 'conversation_handoff',
        'error' => true,
        'error_reason' => Captain::Tools::RunGuard::TOOL_CALL_BUDGET_EXCEEDED
      )
    end
  end

  context 'when the model keeps requesting the same tool with identical arguments' do
    let(:provider) do
      CaptainScriptedLlmProvider.new(tool_name: faq_tool.name, arguments: ->(_index) { { 'query' => 'What services do you offer?' } })
    end

    it 'only executes the repeated call up to the identical-call limit' do
      allow(faq_tool).to receive(:perform).and_call_original

      service.generate_response(message_history: message_history)

      expect(faq_tool).to have_received(:perform).exactly(Captain::Tools::RunGuard::MAX_IDENTICAL_TOOL_CALLS).times
    end

    it 'still ends the run once the tool call budget is spent' do
      response = service.generate_response(message_history: message_history)

      expect(response['error_reason']).to eq(Captain::Tools::RunGuard::TOOL_CALL_BUDGET_EXCEEDED)
    end
  end

  context 'when the model calls a handoff tool' do
    let(:handoff_tool) { Captain::Tools::HandoffTool.new(assistant) }
    let(:tools) { [faq_tool, handoff_tool] }
    let(:provider) do
      CaptainScriptedLlmProvider.new(
        tool_name: handoff_tool.name,
        arguments: ->(_index) { { 'reason' => 'Customer asked for a human', 'reason_category' => 'customer_request' } }
      )
    end

    it 'hands off once and ends the run even though the model asks again' do
      allow(handoff_tool).to receive(:perform).and_call_original
      allow(Captain::ConversationEvents).to receive(:handed_off).and_call_original

      response = service.generate_response(message_history: message_history)

      expect(Captain::ConversationEvents).to have_received(:handed_off).once

      expect(handoff_tool).to have_received(:perform).once
      expect(provider.completions).to eq(1)
      expect(conversation.reload.status).to eq('open')
      expect(conversation.messages.where(private: true).count).to eq(1)
      expect(service.handoff_completed?).to be true
      expect(response).to include('response' => 'conversation_handoff', 'handoff_tool_called' => true)
      expect(response).not_to have_key('error')
    end
  end

  context 'when a newer customer message arrives mid-run' do
    let(:responding_to_message) { create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming) }
    let(:run_options) { described_class::RunOptions.new(responding_to_message_id: responding_to_message.id) }
    let(:label_tool) { Captain::Tools::AddLabelToConversationTool.new(assistant) }
    let(:tools) { [label_tool] }
    let(:provider) do
      CaptainScriptedLlmProvider.new(tool_name: label_tool.name, arguments: ->(index) { { 'label_name' => "sales-#{index}" } })
    end

    before do
      responding_to_message
      create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)
    end

    it 'halts the stale run at the first tool call' do
      allow(label_tool).to receive(:perform).and_call_original

      service.generate_response(message_history: message_history)

      expect(label_tool).not_to have_received(:perform)
      expect(provider.completions).to eq(1)
      expect(service.response_discarded?).to be true
    end
  end

  context 'when the model uses several tools before answering' do
    let(:tools) { [faq_tool, Captain::Tools::AddLabelToConversationTool.new(assistant)] }
    let(:provider) { CaptainScriptedLlmProvider.new(tool_name: faq_tool.name, tool_calls_before_answer: 4) }

    it 'lets the legitimate tool sequence finish and returns the model answer' do
      allow(faq_tool).to receive(:perform).and_call_original

      response = service.generate_response(message_history: message_history)

      expect(faq_tool).to have_received(:perform).exactly(4).times
      expect(response['response']).to eq('Here is your answer')
      expect(response).not_to have_key('error')
    end
  end
end
