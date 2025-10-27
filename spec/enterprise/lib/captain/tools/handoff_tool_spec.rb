require 'rails_helper'

RSpec.describe Captain::Tools::HandoffTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:tool_context) { Struct.new(:state).new({ conversation: { id: conversation.id } }) }

  after do
    # Clean up Current values after each test
    Current.executed_by = nil
    Current.handoff_requested = nil
  end

  describe '#description' do
    it 'returns the correct description' do
      expect(tool.description).to eq('Hand off the conversation to a human agent when unable to assist further')
    end
  end

  describe '#parameters' do
    it 'returns the correct parameters' do
      expect(tool.parameters).to have_key(:reason)
      expect(tool.parameters[:reason].name).to eq(:reason)
      expect(tool.parameters[:reason].type).to eq('string')
      expect(tool.parameters[:reason].description).to eq('The reason why handoff is needed (optional)')
      expect(tool.parameters[:reason].required).to be false
    end
  end

  describe '#perform' do
    context 'when conversation exists' do
      context 'with reason provided' do
        before { conversation.update!(status: :pending) }

        it 'returns success message with reason' do
          reason = 'Customer needs specialized support'
          result = tool.perform(tool_context, reason: reason)
          expect(result).to eq("Conversation handed off to human support team (Reason: #{reason})")
        end

        it 'does not create any messages immediately' do
          # Messages are created by ResponseBuilderJob, not the tool
          expect do
            tool.perform(tool_context, reason: 'Test reason')
          end.not_to change(Message, :count)
        end

        it 'sets Current.handoff_requested flag' do
          tool.perform(tool_context, reason: 'Test reason')

          expect(Current.handoff_requested).to be true
        end

        it 'does not change conversation status immediately' do
          conversation.update(status: :pending)
          expect(conversation.pending?).to be true

          tool.perform(tool_context, reason: 'Customer needs specialized support')

          conversation.reload
          # Status should remain pending until ResponseBuilderJob processes the handoff
          expect(conversation.pending?).to be true
        end

        it 'logs tool usage with reason' do
          reason = 'Customer needs help'
          expect(tool).to receive(:log_tool_usage).with(
            'tool_handoff',
            { conversation_id: conversation.id, reason: reason }
          )

          tool.perform(tool_context, reason: reason)
        end
      end

      context 'without reason provided' do
        before { conversation.update!(status: :pending) }

        it 'returns success message without reason' do
          result = tool.perform(tool_context)
          expect(result).to eq('Conversation handed off to human support team')
        end

        it 'does not create any messages immediately' do
          # Messages are created by ResponseBuilderJob, not the tool
          expect do
            tool.perform(tool_context)
          end.not_to change(Message, :count)
        end

        it 'sets Current.handoff_requested flag' do
          tool.perform(tool_context)

          expect(Current.handoff_requested).to be true
        end

        it 'logs tool usage with default reason' do
          expect(tool).to receive(:log_tool_usage).with(
            'tool_handoff',
            { conversation_id: conversation.id, reason: 'Agent requested handoff' }
          )

          tool.perform(tool_context)
        end
      end

      context 'when an error occurs' do
        it 'returns error message' do
          # Mock an error in trigger_handoff
          allow(Current).to receive(:handoff_requested=).and_raise(StandardError, 'Unexpected error')

          exception_tracker = instance_double(ChatwootExceptionTracker)
          allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
          allow(exception_tracker).to receive(:capture_exception)

          result = tool.perform(tool_context, reason: 'Test')
          expect(result).to eq('Failed to handoff conversation')

          # Unstub to allow cleanup
          allow(Current).to receive(:handoff_requested=).and_call_original
        end

        it 'captures exception' do
          exception_tracker = instance_double(ChatwootExceptionTracker)
          allow(Current).to receive(:handoff_requested=).and_raise(StandardError, 'Unexpected error')

          expect(ChatwootExceptionTracker).to receive(:new).with(instance_of(StandardError)).and_return(exception_tracker)
          expect(exception_tracker).to receive(:capture_exception)

          tool.perform(tool_context, reason: 'Test')

          # Unstub to allow cleanup
          allow(Current).to receive(:handoff_requested=).and_call_original
        end
      end
    end

    context 'when conversation does not exist' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: 999_999 } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, reason: 'Test')
        expect(result).to eq('Conversation not found')
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
        expect(result).to eq('Conversation not found')
      end
    end

    context 'when conversation id is nil' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: nil } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, reason: 'Test')
        expect(result).to eq('Conversation not found')
      end
    end
  end

  describe '#active?' do
    it 'returns true for public tools' do
      expect(tool.active?).to be true
    end
  end
end
