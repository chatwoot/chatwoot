require 'rails_helper'

RSpec.describe Captain::Tools::AddContactNoteTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:tool_context) { Struct.new(:state).new({ contact: { id: contact.id } }) }

  describe '#description' do
    it 'returns the correct description' do
      expect(tool.description).to eq('Append a new note to the contact profile')
    end
  end

  describe '#to_registry_format' do
    it 'returns the correct parameters schema' do
      schema = tool.to_registry_format
      expect(schema[:parameters][:properties]).to have_key(:note)
      expect(schema[:parameters][:properties][:note][:type]).to eq('string')
      expect(schema[:parameters][:properties][:note][:description]).to eq('Content of the note to be added')
    end
  end

  describe '#perform' do
    context 'when contact exists' do
      context 'with valid note content' do
        it 'creates a contact note and returns success message' do
          note_content = 'This is a contact note'

          expect do
            result = tool.perform(tool_context, note: note_content)
            expect(result).to eq("Successfully added note to contact: #{contact.name}")
          end.to change(Note, :count).by(1)

          created_note = Note.last
          expect(created_note.content).to eq(note_content)
          expect(created_note.account).to eq(account)
          expect(created_note.contact).to eq(contact)
          expect(created_note.user).to eq(assistant.account.users.first)
        end

        it 'logs tool usage' do
          expect(tool).to receive(:log_tool_usage).with(
            'contact_note_creation',
            { contact_id: contact.id, length: 19 }
          )

          tool.perform(tool_context, note: 'This is a test note')
        end
      end

      context 'with blank note content' do
        it 'returns error message' do
          result = tool.perform(tool_context, note: '')
          expect(result).to eq('Error: Note content cannot be empty')
        end

        it 'does not create a note' do
          expect do
            tool.perform(tool_context, note: '')
          end.not_to change(Note, :count)
        end
      end

      context 'with nil note content' do
        it 'returns error message' do
          result = tool.perform(tool_context, note: nil)
          expect(result).to eq('Error: Note content cannot be empty')
        end
      end
    end

    context 'when contact does not exist' do
      let(:tool_context) { Struct.new(:state).new({ contact: { id: 999_999 } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, note: 'Some note')
        expect(result).to eq('Error: Contact context missing')
      end

      it 'does not create a note' do
        expect do
          tool.perform(tool_context, note: 'Some note')
        end.not_to change(Note, :count)
      end
    end

    context 'when contact state is missing' do
      let(:tool_context) { Struct.new(:state).new({}) }

      it 'returns error message' do
        result = tool.perform(tool_context, note: 'Some note')
        expect(result).to eq('Error: Contact context missing')
      end
    end

    context 'when contact id is nil' do
      let(:tool_context) { Struct.new(:state).new({ contact: { id: nil } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, note: 'Some note')
        expect(result).to eq('Error: Contact context missing')
      end
    end
  end

  describe '#active?' do
    it 'returns true for public tools' do
      expect(tool.active?).to be true
    end
  end
end
