require 'rails_helper'

describe Whatsapp::BaileysHandlers::GroupParticipantsUpdate do
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
    params = { webhookVerifyToken: webhook_verify_token, event: 'group-participants.update', data: data }
    Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
  end

  def create_group_conversation
    contact = create(:contact, account: inbox.account, identifier: group_jid, group_type: :group)
    contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: group_source_id)
    conversation = create(:conversation, account: inbox.account, inbox: inbox, contact: contact,
                                         contact_inbox: contact_inbox, group_type: :group, status: :open)
    [conversation, contact]
  end

  def participant(id, phone, admin: nil)
    { id: id, phoneNumber: phone, admin: admin }
  end

  describe 'add action' do
    it 'adds participants as group members and creates activity message' do
      conversation, group_contact = create_group_conversation
      author_lid = '99999999'
      author_contact = create(:contact, account: inbox.account, name: 'Admin User')
      create(:contact_inbox, inbox: inbox, contact: author_contact, source_id: author_lid)

      perform(id: group_jid, action: 'add', author: "#{author_lid}@lid",
              participants: [participant('11111111@lid', '5511911111111@s.whatsapp.net')])

      member = GroupMember.find_by(group_contact: group_contact, contact: Contact.find_by(phone_number: '+5511911111111'))

      expect(member).to be_is_active
      expect(member.role).to eq('member')
      expect(conversation.messages.activity.last.content).to include('Admin User', 'added')
    end
  end

  describe 'join action (add without author)' do
    it 'creates join activity when participant adds themselves' do
      conversation, = create_group_conversation

      perform(id: group_jid, action: 'add', author: nil,
              participants: [participant('11111111@lid', '5511911111111@s.whatsapp.net')])

      activity = conversation.messages.activity.last

      expect(activity.content).to include('joined')
    end
  end

  describe 'remove action' do
    it 'deactivates the member and creates activity message' do
      conversation, group_contact = create_group_conversation
      removed_contact = create(:contact, account: inbox.account, phone_number: '+5511911111111')
      create(:contact_inbox, inbox: inbox, contact: removed_contact, source_id: '11111111')
      GroupMember.create!(group_contact: group_contact, contact: removed_contact)

      perform(id: group_jid, action: 'remove', author: '99999999@lid',
              participants: [participant('11111111@lid', '5511911111111@s.whatsapp.net')])

      expect(GroupMember.find_by(group_contact: group_contact, contact: removed_contact)).not_to be_is_active
      expect(conversation.messages.activity.last.content).to include('removed')
    end
  end

  describe 'leave action (remove by self)' do
    it 'creates leave activity when participant removes themselves' do
      conversation, group_contact = create_group_conversation
      leaving_contact = create(:contact, account: inbox.account, phone_number: '+5511911111111')
      create(:contact_inbox, inbox: inbox, contact: leaving_contact, source_id: '11111111')
      GroupMember.create!(group_contact: group_contact, contact: leaving_contact)

      perform(id: group_jid, action: 'remove', author: '5511911111111@s.whatsapp.net',
              participants: [participant('11111111@lid', '5511911111111@s.whatsapp.net')])

      expect(conversation.messages.activity.last.content).to include('left')
    end
  end

  describe 'promote action' do
    it 'updates member role to admin and creates activity message' do
      conversation, group_contact = create_group_conversation
      contact = create(:contact, account: inbox.account)
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: '11111111')
      GroupMember.create!(group_contact: group_contact, contact: contact, role: :member)

      perform(id: group_jid, action: 'promote', author: '99999999@lid',
              participants: [participant('11111111@lid', '5511911111111@s.whatsapp.net')])

      expect(GroupMember.find_by(group_contact: group_contact, contact: contact).role).to eq('admin')
      expect(conversation.messages.activity.last.content).to include('promoted')
    end
  end

  describe 'demote action' do
    it 'updates member role to member and creates activity message' do
      conversation, group_contact = create_group_conversation
      contact = create(:contact, account: inbox.account)
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: '11111111')
      GroupMember.create!(group_contact: group_contact, contact: contact, role: :admin)

      perform(id: group_jid, action: 'demote', author: '99999999@lid',
              participants: [participant('11111111@lid', '5511911111111@s.whatsapp.net')])

      expect(GroupMember.find_by(group_contact: group_contact, contact: contact).role).to eq('member')
      expect(conversation.messages.activity.last.content).to include('demoted')
    end
  end
end
