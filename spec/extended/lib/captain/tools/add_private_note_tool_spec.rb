require 'rails_helper'

RSpec.describe Captain::Tools::AddPrivateNoteTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:tool_context) { Struct.new(:state).new({ conversation: { id: conversation.id } }) }

  describe '#description' do
    it 'returns the correct description' do
      expect(tool.description).to eq('Create a private internal note on the conversation')
    end
  end

  describe '#to_registry_format' do
    it 'returns the correct parameters schema' do
      schema = tool.to_registry_format
      expect(schema[:parameters][:properties]).to have_key(:note)
      expect(schema[:parameters][:properties][:note][:type]).to eq('string')
      expect(schema[:parameters][:properties][:note][:description]).to eq('Text content of the private note')
    end
  end

  describe '#perform' do
    context 'when conversation exists' do
      context 'with valid note content' do
        it 'creates a private note and returns success message' do
          note_content = 'This is a private note'

          expect do
            result = tool.perform(tool_context, note: note_content)
            expect(result).to eq('Private note successfully recorded')
          end.to change(Message, :count).by(1)

          created_message = Message.last
          expect(created_message.content).to eq(note_content)
          expect(created_message.private).to be true
          expect(created_message.message_type).to eq('outgoing')
          expect(created_message.sender).to eq(assistant)
          expect(created_message.account).to eq(account)
          expect(created_message.inbox).to eq(inbox)
        end

        it 'logs tool usage' do
          expect(tool).to receive(:log_tool_usage).with(
            'private_note_created',
            { conversation_id: conversation.id, length: 19 }
          )

          tool.perform(tool_context, note: 'This is a test note')
        end
      end

      context 'with blank note content' do
        it 'returns error message' do
          result = tool.perform(tool_context, note: '')
          expect(result).to eq('Error: Note content cannot be empty')
        end

        it 'does not create a message' do
          expect do
            tool.perform(tool_context, note: '')
          end.not_to change(Message, :count)
        end
      end

      context 'with nil note content' do
        it 'returns error message' do
          result = tool.perform(tool_context, note: nil)
          expect(result).to eq('Error: Note content cannot be empty')
        end
      end
    end

    context 'when conversation does not exist' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: 999_999 } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, note: 'Some note')
        expect(result).to eq('Error: Conversation context missing')
      end

      it 'does not create a message' do
        expect do
          tool.perform(tool_context, note: 'Some note')
        end.not_to change(Message, :count)
      end
    end

    context 'when conversation state is missing' do
      let(:tool_context) { Struct.new(:state).new({}) }

      it 'returns error message' do
        result = tool.perform(tool_context, note: 'Some note')
        expect(result).to eq('Error: Conversation context missing')
      end
    end

    context 'when conversation id is nil' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: nil } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, note: 'Some note')
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
