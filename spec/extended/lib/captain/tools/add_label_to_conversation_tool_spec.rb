require 'rails_helper'

RSpec.describe Captain::Tools::AddLabelToConversationTool, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:tool) { described_class.new(assistant) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:label) { create(:label, title: 'urgent', account: account) }
  let(:tool_context) { Struct.new(:state).new({ conversation: { id: conversation.id } }) }

  describe '#description' do
    it 'returns the correct description' do
      expect(tool.description).to eq('Attach a label to the current conversation')
    end
  end

  describe '#to_registry_format' do
    it 'returns the correct parameters schema' do
      schema = tool.to_registry_format
      expect(schema[:parameters][:properties]).to have_key(:label_name)
      expect(schema[:parameters][:properties][:label_name][:type]).to eq('string')
      expect(schema[:parameters][:properties][:label_name][:description]).to eq('Name of the label to apply')
    end
  end

  describe '#perform' do
    context 'when conversation exists' do
      context 'with valid label that exists' do
        before { label } # Ensure label exists

        it 'adds label to conversation and returns success message' do
          result = tool.perform(tool_context, label_name: 'urgent')
          expect(result).to eq("Label 'urgent' successfully applied to conversation")
          expect(conversation.reload.label_list).to include('urgent')
        end

        it 'logs tool usage' do
          expect(tool).to receive(:log_tool_usage).with(
            'label_applied',
            { conversation_id: conversation.id, label: 'urgent' }
          )

          tool.perform(tool_context, label_name: 'urgent')
        end

        it 'handles case insensitive label names' do
          result = tool.perform(tool_context, label_name: 'URGENT')
          expect(result).to eq("Label 'urgent' successfully applied to conversation")
        end

        it 'strips whitespace from label names' do
          result = tool.perform(tool_context, label_name: '  urgent  ')
          expect(result).to eq("Label 'urgent' successfully applied to conversation")
        end
      end

      context 'with label that does not exist' do
        it 'returns error message' do
          result = tool.perform(tool_context, label_name: 'nonexistent')
          expect(result).to eq("Error: Label 'nonexistent' does not exist")
        end

        it 'does not add label to conversation' do
          expect do
            tool.perform(tool_context, label_name: 'nonexistent')
          end.not_to(change { conversation.reload.label_list })
        end
      end

      context 'with blank label name' do
        it 'returns error message for empty string' do
          result = tool.perform(tool_context, label_name: '')
          expect(result).to eq('Error: Label name required')
        end

        it 'returns error message for nil' do
          result = tool.perform(tool_context, label_name: nil)
          expect(result).to eq('Error: Label name required')
        end

        it 'returns error message for whitespace only' do
          result = tool.perform(tool_context, label_name: '   ')
          expect(result).to eq('Error: Label name required')
        end
      end
    end

    context 'when conversation does not exist' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: 999_999 } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, label_name: 'urgent')
        expect(result).to eq('Error: Conversation context missing')
      end
    end

    context 'when conversation state is missing' do
      let(:tool_context) { Struct.new(:state).new({}) }

      it 'returns error message' do
        result = tool.perform(tool_context, label_name: 'urgent')
        expect(result).to eq('Error: Conversation context missing')
      end
    end

    context 'when conversation id is nil' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: nil } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, label_name: 'urgent')
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
