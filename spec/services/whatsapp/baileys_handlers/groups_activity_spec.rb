require 'rails_helper'

describe Whatsapp::BaileysHandlers::GroupsActivity do
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
    params = { webhookVerifyToken: webhook_verify_token, event: 'groups.activity', data: data }
    Whatsapp::IncomingMessageBaileysService.new(inbox: inbox, params: params).perform
  end

  def create_group_conversation
    contact = create(:contact, account: inbox.account, identifier: group_jid, group_type: :group, name: group_source_id)
    contact_inbox = create(:contact_inbox, inbox: inbox, contact: contact, source_id: group_source_id)
    conversation = create(:conversation, account: inbox.account, inbox: inbox, contact: contact,
                                         contact_inbox: contact_inbox, group_type: :group, status: :open)
    [conversation, contact, contact_inbox]
  end

  describe 'existing group conversation' do
    it 'updates last_activity_at on the conversation' do
      conversation, = create_group_conversation
      original_activity = conversation.last_activity_at

      travel_to 1.minute.from_now do
        perform([{ jid: group_jid }])
        expect(conversation.reload.last_activity_at).to be > original_activity
      end
    end

    it 'enqueues SyncGroupJob in soft mode for the contact' do
      _conversation, contact, = create_group_conversation
      perform([{ jid: group_jid }])
      expect(Contacts::SyncGroupJob).to have_been_enqueued.with(contact, soft: true)
    end
  end

  describe 'group that does not exist yet' do
    it 'creates the group contact, contact_inbox, and conversation' do
      expect { perform([{ jid: group_jid }]) }
        .to change(Contact, :count).by(1)
        .and change(ContactInbox, :count).by(1)
        .and change(Conversation, :count).by(1)

      contact = Contact.find_by(identifier: group_jid, account: inbox.account)
      expect(contact).to be_present
      expect(contact.group_type).to eq('group')

      conversation = contact.conversations.last
      expect(conversation.group_type).to eq('group')
      expect(conversation.inbox).to eq(inbox)
    end

    it 'enqueues SyncGroupJob in soft mode for the new contact' do
      perform([{ jid: group_jid }])
      contact = Contact.find_by(identifier: group_jid, account: inbox.account)
      expect(Contacts::SyncGroupJob).to have_been_enqueued.with(contact, soft: true)
    end
  end

  describe 'skips invalid data' do
    it 'skips activities with blank jid' do
      expect { perform([{ jid: '' }]) }.not_to change(Conversation, :count)
    end

    it 'handles empty data gracefully' do
      expect { perform(nil) }.not_to raise_error
    end
  end
end
