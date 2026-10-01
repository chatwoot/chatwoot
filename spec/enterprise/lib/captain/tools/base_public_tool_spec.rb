# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::BasePublicTool do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { Captain::Tools::AddLabelToConversationTool.new(assistant) }
  let(:tool_context) { Struct.new(:state).new({ conversation: { id: conversation.id } }) }

  describe '#execute' do
    it 'runs the tool while the run stays within its budget' do
      create(:label, account: account, title: 'sales')

      expect(tool.execute(tool_context, label_name: 'sales')).to include('sales')
      expect(conversation.reload.label_list).to include('sales')
    end

    it 'halts the run when the tool call budget is exhausted' do
      allow(tool).to receive(:perform).and_call_original
      budget = Captain::Tools::RunGuard::MAX_TOOL_CALLS_PER_RUN

      results = Array.new(budget + 1) { |index| tool.execute(tool_context, label_name: "label-#{index}") }

      expect(tool).to have_received(:perform).exactly(budget).times
      expect(results.last).to be_a(RubyLLM::Tool::Halt)
      expect(results.last.content).to eq(Captain::Tools::RunGuard::BUDGET_EXCEEDED_MESSAGE)
      expect(Captain::Tools::RunGuard.halt_reason(tool_context.state)).to eq(Captain::Tools::RunGuard::TOOL_CALL_BUDGET_EXCEEDED)
    end

    it 'skips the tool without side effects when the same call repeats too often' do
      allow(tool).to receive(:perform).and_call_original
      repeat_limit = Captain::Tools::RunGuard::MAX_IDENTICAL_TOOL_CALLS

      results = Array.new(repeat_limit + 2) { tool.execute(tool_context, label_name: 'sales') }

      expect(tool).to have_received(:perform).exactly(repeat_limit).times
      expect(results.last).to eq(Captain::Tools::RunGuard::REPEATED_CALL_MESSAGE)
      expect(Captain::Tools::RunGuard.halt_reason(tool_context.state)).to be_nil
    end

    it 'logs the tool and run details when a guard trips' do
      allow(Rails.logger).to receive(:warn)

      (Captain::Tools::RunGuard::MAX_IDENTICAL_TOOL_CALLS + 1).times { tool.execute(tool_context, label_name: 'sales') }

      expect(Rails.logger).to have_received(:warn) do |&message|
        expect(message.call).to include('repeated_tool_call_skipped', "assistant=#{assistant.id}", "conversation=#{conversation.id}")
      end
    end

    context 'when a newer customer message arrived' do
      let(:responding_to_message) { create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming) }
      let(:tool_context) do
        Struct.new(:state).new({ conversation: { id: conversation.id }, responding_to_message_id: responding_to_message.id })
      end

      before do
        responding_to_message
        create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)
      end

      it 'halts the stale run instead of returning a result the model can ignore' do
        allow(tool).to receive(:perform).and_call_original

        result = tool.execute(tool_context, label_name: 'sales')

        expect(tool).not_to have_received(:perform)
        expect(result).to be_a(RubyLLM::Tool::Halt)
        expect(result.content).to eq(Captain::Tools::BasePublicTool::STALE_RUN_MESSAGE)
        expect(Captain::Tools::RunGuard.halt_reason(tool_context.state)).to eq(Captain::Tools::RunGuard::STALE_RUN)
      end

      it 'keeps running tools that are safe after a new customer message' do
        faq_tool = Captain::Tools::FaqLookupTool.new(assistant)
        allow(Captain::AssistantResponse).to receive(:search).and_return(Captain::AssistantResponse.none)

        result = faq_tool.execute(tool_context, query: 'pricing')

        expect(result).to eq('No relevant FAQs found for: pricing')
        expect(Captain::Tools::RunGuard.halt_reason(tool_context.state)).to be_nil
      end
    end
  end
end
