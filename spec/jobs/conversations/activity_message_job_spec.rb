require 'rails_helper'

RSpec.describe Conversations::ActivityMessageJob do
  describe '#perform' do
    let(:conversation) { create(:conversation) }
    let(:message_params) do
      {
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        message_type: :activity,
        content: 'Conversation activity'
      }
    end

    it 'drops locked activity messages without raising' do
      conversation.lock_message_creation!

      expect do
        described_class.perform_now(conversation, message_params)
      end.not_to change(Message, :count)
    end
  end
end
