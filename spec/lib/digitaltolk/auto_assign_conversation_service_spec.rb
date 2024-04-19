require 'rails_helper'

describe Digitaltolk::AutoAssignConversationService do
  let(:service) { described_class.new }
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  describe '#perform' do
    it 'autoes assign' do
      expect(conversation.assignee_id).to eq(nil)
      create(:inbox_member, inbox: inbox, user: agent)
      create(:message, conversation: conversation, message_type: 'outgoing', sender: agent)
      service.perform
      expect(conversation.reload.assignee_id).to eq(agent.id)
    end
  end
end
