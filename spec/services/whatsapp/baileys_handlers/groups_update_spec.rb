require 'rails_helper'

describe Whatsapp::BaileysHandlers::GroupsUpdate do
  let(:webhook_verify_token) { 'valid_token' }
  let!(:whatsapp_channel) do
    create(:channel_whatsapp,
           provider: 'baileys',
           provider_config: { webhook_verify_token: webhook_verify_token },
           validate_provider_config: false,
           received_messages: false)
  end
  let(:inbox) { whatsapp_channel.inbox }
  let(:group_jid) { '123456789@g.us' }
  let(:group_source_id) { '123456789' }

  def perform(data)
    params = { webhookVerifyToken: webhook_verify_token, event: 'groups.update', data: data }
    Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
  end

  def create_group_conversation(name: group_source_id)
    contact = create(:contact, account: inbox.account, identifier: group_jid, group_type: :group, name: name)
    contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: group_source_id)
    conversation = create(:conversation, account: inbox.account, inbox: inbox, contact: contact,
                                         contact_inbox: contact_inbox, group_type: :group, status: :open)
    [conversation, contact]
  end

  describe 'subject change' do
    it 'updates the group contact name and creates activity message' do
      conversation, contact = create_group_conversation(name: 'Old Name')

      perform([{ id: group_jid, subject: 'New Group Name', author: '99999999@lid' }])

      expect(contact.reload.name).to eq('New Group Name')
      expect(conversation.messages.activity.last.content).to include('New Group Name')
    end
  end

  describe 'description change' do
    it 'creates activity when description is set' do
      conversation, = create_group_conversation

      perform([{ id: group_jid, desc: 'A new description', author: '99999999@lid' }])

      expect(conversation.messages.activity.last.content).to include('changed the group description')
    end

    it 'creates activity when description is removed' do
      conversation, = create_group_conversation

      perform([{ id: group_jid, desc: '', author: '99999999@lid' }])

      expect(conversation.messages.activity.last.content).to include('removed the group description')
    end
  end

  describe 'invite link reset' do
    it 'creates activity message' do
      conversation, = create_group_conversation

      perform([{ id: group_jid, inviteCode: 'abc123', author: '99999999@lid' }])

      expect(conversation.messages.activity.last.content).to include('invite link')
    end
  end

  describe 'settings changes' do
    it 'creates activity for restrict enabled' do
      conversation, = create_group_conversation

      perform([{ id: group_jid, restrict: true, author: '99999999@lid' }])

      expect(conversation.messages.activity.last.content).to include('only admins can edit')
    end

    it 'creates activity for announce enabled' do
      conversation, = create_group_conversation

      perform([{ id: group_jid, announce: true, author: '99999999@lid' }])

      expect(conversation.messages.activity.last.content).to include('only admins to send messages')
    end

    it 'creates activity for joinApprovalMode toggled' do
      conversation, = create_group_conversation

      perform([{ id: group_jid, joinApprovalMode: true, author: '99999999@lid' }])

      expect(conversation.messages.activity.last.content).to include('admin approval')
    end
  end
end
