require 'rails_helper'

RSpec.describe Captain::Tools::HandoffTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:tool_context) { Struct.new(:state).new({ conversation: { id: conversation.id } }) }

  describe '#description' do
    it 'returns the correct description' do
      expect(tool.description).to eq('Transfer the conversation to a human support agent')
    end
  end

  describe '#to_registry_format' do
    it 'returns the correct parameters schema' do
      schema = tool.to_registry_format
      expect(schema[:parameters][:properties]).to have_key(:reason)
      expect(schema[:parameters][:properties][:reason][:type]).to eq('string')
      expect(schema[:parameters][:properties][:reason][:description]).to eq('Optional explanation for why the handoff is occurring')
    end
  end

  describe '#perform' do
    context 'when conversation exists' do
      context 'with reason provided' do
        let(:reason) { 'Customer needs specialized support' }

        it 'creates a private note with reason and hands off conversation' do
          expect do
            result = tool.perform(tool_context, reason: reason)
            expect(result).to eq("Conversation transferred to support team. Reason: #{reason}")
          end.to change(Message, :count).by(1)

          created_message = Message.last
          expect(created_message.content).to eq(reason)
          expect(created_message.private).to be true
          expect(created_message.message_type).to eq('outgoing')
          expect(created_message.sender).to eq(assistant)

          expect(conversation.reload.status).to eq('open')
        end

        it 'logs tool usage with reason' do
          reason = 'Customer needs help'
          expect(tool).to receive(:log_tool_usage).with(
            'handoff_triggered',
            { conversation_id: conversation.id, reason: reason }
          )

          tool.perform(tool_context, reason: reason)
        end
      end

      context 'without reason provided' do
        it 'creates a private note with nil content and hands off conversation' do
          expect do
            result = tool.perform(tool_context)
            expect(result).to eq('Conversation transferred to support team. Reason: User requested human assistance')
          end.to change(Message, :count).by(1)
        end

        it 'logs tool usage with default reason' do
          expect(tool).to receive(:log_tool_usage).with(
            'handoff_triggered',
            { conversation_id: conversation.id, reason: 'User requested human assistance' }
          )

          tool.perform(tool_context)
        end
      end

      context 'when handoff fails' do
        before do
          # Stub the find_conversation method to return our conversation
          allow(tool).to receive(:find_conversation).and_return(conversation)
          # Mock the bot_handoff! method to raise an error
          allow(conversation).to receive(:bot_handoff!).and_raise(StandardError, 'Handoff error')
        end

        it 'returns error message' do
          result = tool.perform(tool_context, reason: 'Test')
          expect(result).to eq('Handoff failed due to an internal error')
        end

        it 'tracks exception' do
          expect(ChatwootExceptionTracker).to receive(:new).and_call_original

          tool.perform(tool_context, reason: 'Test')
        end
      end
    end

    context 'when conversation does not exist' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: 999_999 } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, reason: 'Test')
        expect(result).to eq('Error: Conversation context missing')
      end

      it 'does not create a message' do
        expect do
          tool.perform(tool_context, reason: 'Test')
        end.not_to change(Message, :count)
      end
    end

    context 'when conversation state is missing' do
      let(:tool_context) { Struct.new(:state).new({}) }

      it 'returns error message' do
        result = tool.perform(tool_context, reason: 'Test')
        expect(result).to eq('Error: Conversation context missing')
      end
    end

    context 'when conversation id is nil' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: nil } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, reason: 'Test')
        expect(result).to eq('Error: Conversation context missing')
      end
    end
  end

  describe '#active?' do
    it 'returns true for public tools' do
      expect(tool.active?).to be true
    end
  end
end
