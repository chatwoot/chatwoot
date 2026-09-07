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
      expect(tool.description).to eq('Add a private note to a conversation')
    end
  end

  describe '#parameters' do
    it 'returns the correct parameters' do
      expect(tool.parameters).to have_key(:note)
      expect(tool.parameters[:note].name).to eq(:note)
      expect(tool.parameters[:note].type).to eq('string')
      expect(tool.parameters[:note].description).to eq('The private note content')
    end
  end

  describe '#perform' do
    context 'when conversation exists' do
      context 'with valid note content' do
        it 'creates a private note and returns success message' do
          note_content = 'This is a private note'

          expect do
            result = tool.perform(tool_context, note: note_content)
            expect(result).to eq('Private note added successfully')
          end.to change(Message, :count).by(1)
        end

        it 'creates a private note with correct attributes' do
          note_content = 'This is a private note'

          tool.perform(tool_context, note: note_content)

          created_message = Message.last
          expect(created_message.content).to eq(note_content)
          expect(created_message.message_type).to eq('outgoing')
          expect(created_message.private).to be true
          expect(created_message.account).to eq(account)
          expect(created_message.inbox).to eq(inbox)
          expect(created_message.conversation).to eq(conversation)
        end

        it 'logs tool usage' do
          expect(tool).to receive(:log_tool_usage).with(
            'add_private_note',
            { conversation_id: conversation.id, note_length: 19 }
          )

          tool.perform(tool_context, note: 'This is a test note')
        end
      end

      context 'with blank note content' do
        it 'returns error message' do
          result = tool.perform(tool_context, note: '')
          expect(result).to eq('Note content is required')
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
          expect(result).to eq('Note content is required')
        end
      end
    end

    context 'when conversation does not exist' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: 999_999 } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, note: 'Some note')
        expect(result).to eq('Conversation not found')
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
        expect(result).to eq('Conversation not found')
      end
    end

    context 'when conversation id is nil' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: nil } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, note: 'Some note')
        expect(result).to eq('Conversation not found')
      end
    end
  end

  describe '#execute' do
    let(:responding_to_message) do
      create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)
    end
    let(:tool_context) do
      Struct.new(:state).new({ conversation: { id: conversation.id }, responding_to_message_id: responding_to_message.id })
    end

    before do
      responding_to_message
      create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming)
    end

    it 'keeps legacy public-tool side effects for Captain V1' do
      expect do
        result = tool.execute(tool_context, note: 'Keep the legacy side effect')
        expect(result).to eq('Private note added successfully')
      end.to change(Message, :count).by(1)
    end

    it 'skips stale public-tool side effects for Captain V2' do
      account.enable_features!(:captain_integration_v2)

      expect do
        result = tool.execute(tool_context, note: 'Do not create this note')
        expect(result).to eq('Tool skipped because a newer customer message arrived')
      end.not_to change(Message, :count)
    end
  end

  describe '#active?' do
    it 'returns true for public tools' do
      expect(tool.active?).to be true
    end
  end
end
