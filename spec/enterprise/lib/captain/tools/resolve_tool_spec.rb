require 'rails_helper'

RSpec.describe Captain::Tools::ResolveTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, status: :open) }
  let(:tool_context) { Struct.new(:state).new({ conversation: { id: conversation.id } }) }

  describe '#description' do
    it 'returns the correct description' do
      expect(tool.description).to eq('Mark the conversation as resolved when the issue has been addressed')
    end
  end

  describe '#parameters' do
    it 'returns the correct parameters' do
      expect(tool.parameters).to have_key(:reason)
      expect(tool.parameters[:reason].name).to eq(:reason)
      expect(tool.parameters[:reason].type).to eq('string')
      expect(tool.parameters[:reason].description).to eq('The reason why the conversation is being resolved (optional)')
      expect(tool.parameters[:reason].required).to be false
    end
  end

  describe '#perform' do
    context 'when conversation exists and is not resolved' do
      context 'with reason provided' do
        it 'creates a private note with reason and resolves conversation' do
          reason = 'Customer issue has been fixed'

          expect do
            result = tool.perform(tool_context, reason: reason)
            expect(result).to eq("Conversation marked as resolved (Reason: #{reason})")
          end.to change(Message, :count).by(1)
        end

        it 'creates message with correct attributes' do
          reason = 'Customer issue has been fixed'
          tool.perform(tool_context, reason: reason)

          created_message = Message.last
          expect(created_message.content).to eq("Resolved: #{reason}")
          expect(created_message.message_type).to eq('outgoing')
          expect(created_message.private).to be true
          expect(created_message.sender).to eq(assistant)
          expect(created_message.account).to eq(account)
          expect(created_message.inbox).to eq(inbox)
          expect(created_message.conversation).to eq(conversation)
        end

        it 'marks conversation as resolved' do
          expect(conversation.status).to eq('open')

          tool.perform(tool_context, reason: 'Issue fixed')

          expect(conversation.reload.status).to eq('resolved')
        end

        it 'logs tool usage with reason' do
          reason = 'Customer satisfied'
          expect(tool).to receive(:log_tool_usage).with(
            'tool_resolve',
            { conversation_id: conversation.id, reason: reason }
          )

          tool.perform(tool_context, reason: reason)
        end
      end

      context 'without reason provided' do
        it 'resolves conversation without creating a private note' do
          expect do
            result = tool.perform(tool_context)
            expect(result).to eq('Conversation marked as resolved')
          end.not_to change(Message, :count)
        end

        it 'marks conversation as resolved' do
          expect(conversation.status).to eq('open')

          tool.perform(tool_context)

          expect(conversation.reload.status).to eq('resolved')
        end

        it 'logs tool usage with default reason' do
          expect(tool).to receive(:log_tool_usage).with(
            'tool_resolve',
            { conversation_id: conversation.id, reason: 'Agent resolved conversation' }
          )

          tool.perform(tool_context)
        end
      end

      context 'when resolve fails' do
        before do
          found_conversation = Conversation.find(conversation.id)
          scoped_conversations = Conversation.where(account_id: assistant.account_id)
          allow(Conversation).to receive(:where).with(account_id: assistant.account_id).and_return(scoped_conversations)
          allow(scoped_conversations).to receive(:find_by).with(id: conversation.id).and_return(found_conversation)
          allow(found_conversation).to receive(:resolved!).and_raise(StandardError, 'Resolve error')

          exception_tracker = instance_double(ChatwootExceptionTracker)
          allow(ChatwootExceptionTracker).to receive(:new).and_return(exception_tracker)
          allow(exception_tracker).to receive(:capture_exception)
        end

        it 'returns error message' do
          result = tool.perform(tool_context, reason: 'Test')
          expect(result).to eq('Failed to resolve conversation')
        end

        it 'captures exception' do
          exception_tracker = instance_double(ChatwootExceptionTracker)
          expect(ChatwootExceptionTracker).to receive(:new).with(instance_of(StandardError)).and_return(exception_tracker)
          expect(exception_tracker).to receive(:capture_exception)

          tool.perform(tool_context, reason: 'Test')
        end
      end
    end

    context 'when conversation is already resolved' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, status: :resolved) }

      it 'returns message that conversation is already resolved' do
        result = tool.perform(tool_context, reason: 'Test')
        expect(result).to eq('Conversation is already resolved')
      end

      it 'does not create a message' do
        expect do
          tool.perform(tool_context, reason: 'Test')
        end.not_to change(Message, :count)
      end

      it 'does not change conversation status' do
        expect do
          tool.perform(tool_context, reason: 'Test')
        end.not_to(change { conversation.reload.status })
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
