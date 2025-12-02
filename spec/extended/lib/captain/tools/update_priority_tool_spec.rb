require 'rails_helper'

RSpec.describe Captain::Tools::UpdatePriorityTool, type: :model do
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
      expect(tool.description).to eq('Modify the priority level of the active conversation')
    end
  end

  describe '#to_registry_format' do
    it 'returns the correct parameters schema' do
      schema = tool.to_registry_format
      props = schema[:parameters][:properties]

      expect(props).to have_key(:priority)
      expect(props[:priority][:type]).to eq('string')
      expect(props[:priority][:description]).to eq('New priority: low, medium, high, urgent, or nil to clear')
    end
  end

  describe '#perform' do
    context 'when conversation exists' do
      context 'with valid priority levels' do
        %w[low medium high urgent].each do |priority|
          it "updates conversation priority to #{priority}" do
            result = tool.perform(tool_context, priority: priority)
            expect(result).to eq("Priority successfully changed to '#{priority}' for conversation ##{conversation.display_id}")

            expect(conversation.reload.priority).to eq(priority)
          end
        end

        it 'removes priority when set to nil' do
          conversation.update!(priority: 'high')

          result = tool.perform(tool_context, priority: 'nil')
          expect(result).to eq("Priority successfully changed to 'none' for conversation ##{conversation.display_id}")

          expect(conversation.reload.priority).to be_nil
        end

        it 'removes priority when set to empty string' do
          conversation.update!(priority: 'high')

          result = tool.perform(tool_context, priority: '')
          expect(result).to eq("Priority successfully changed to 'none' for conversation ##{conversation.display_id}")

          expect(conversation.reload.priority).to be_nil
        end

        it 'logs tool usage' do
          expect(tool).to receive(:log_tool_usage).with(
            'priority_update',
            { conversation_id: conversation.id, new_priority: 'high' }
          )

          tool.perform(tool_context, priority: 'high')
        end
      end

      context 'with invalid priority levels' do
        it 'returns error message for invalid priority' do
          result = tool.perform(tool_context, priority: 'invalid')
          expect(result).to include("Error: Invalid priority 'invalid'")
        end

        it 'does not update conversation priority' do
          original_priority = conversation.priority

          tool.perform(tool_context, priority: 'invalid')

          expect(conversation.reload.priority).to eq(original_priority)
        end
      end
    end

    context 'when conversation does not exist' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: 999_999 } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, priority: 'high')
        expect(result).to eq('Error: Conversation context missing')
      end
    end

    context 'when conversation state is missing' do
      let(:tool_context) { Struct.new(:state).new({}) }

      it 'returns error message' do
        result = tool.perform(tool_context, priority: 'high')
        expect(result).to eq('Error: Conversation context missing')
      end
    end

    context 'when conversation id is nil' do
      let(:tool_context) { Struct.new(:state).new({ conversation: { id: nil } }) }

      it 'returns error message' do
        result = tool.perform(tool_context, priority: 'high')
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
