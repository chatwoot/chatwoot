require 'rails_helper'

RSpec.describe Contacts::SyncGroupService do
  describe '#perform' do
    it 'raises BadRequest when contact is not a group' do
      contact = create(:contact, group_type: :individual, identifier: 'group@g.us')

      expect { described_class.new(contact: contact).perform }.to raise_error(ActionController::BadRequest)
    end

    it 'raises BadRequest when contact has no identifier' do
      contact = create(:contact, group_type: :group, identifier: nil)

      expect { described_class.new(contact: contact).perform }.to raise_error(ActionController::BadRequest)
    end

    it 'raises BadRequest when no channel supports sync_group' do
      contact = create(:contact, group_type: :group, identifier: 'group@g.us')

      expect { described_class.new(contact: contact).perform }.to raise_error(ActionController::BadRequest)
    end

    it 'calls channel.sync_group with a conversation' do
      channel = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false)
      contact = create(:contact, account: channel.account, group_type: :group, identifier: 'group@g.us')
      contact_inbox = create(:contact_inbox, contact: contact, inbox: channel.inbox)
      conversation = create(:conversation, account: channel.account, inbox: channel.inbox, contact: contact, contact_inbox: contact_inbox)

      allow(channel).to receive(:sync_group).and_return(true)
      allow(contact).to receive(:group_channel).and_return(channel)

      described_class.new(contact: contact).perform

      expect(channel).to have_received(:sync_group).with(conversation, soft: false)
    end

    it 'dispatches contact_group_synced event' do
      channel = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false)
      contact = create(:contact, account: channel.account, group_type: :group, identifier: 'group@g.us')
      contact_inbox = create(:contact_inbox, contact: contact, inbox: channel.inbox)
      create(:conversation, account: channel.account, inbox: channel.inbox, contact: contact, contact_inbox: contact_inbox)

      allow(channel).to receive(:sync_group).and_return(true)
      allow(contact).to receive(:group_channel).and_return(channel)

      expect(Rails.configuration.dispatcher).to receive(:dispatch)
        .with(Events::Types::CONTACT_GROUP_SYNCED, anything, contact: contact)

      described_class.new(contact: contact).perform
    end
  end
end
