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

    # The caller that supplied a channel means "sync this group as that inbox sees it".
    # Taking the contact's first contact_inbox drove the supplied channel with a
    # conversation belonging to another inbox, writing the result into the wrong one.
    it 'takes the conversation from the supplied channel inbox, not the first one' do
      account = create(:account)
      first = create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false)
      second = create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false)
      contact = create(:contact, account: account, group_type: :group, identifier: 'group@g.us')
      create(:contact_inbox, contact: contact, inbox: first.inbox)
      wanted = create(:contact_inbox, contact: contact, inbox: second.inbox)

      allow(second).to receive(:sync_group).and_return(true)

      described_class.new(contact: contact, channel: second).perform

      expect(second).to have_received(:sync_group) do |conversation, **|
        expect(conversation.contact_inbox_id).to eq(wanted.id)
      end
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
        .with(Events::Types::CONTACT_GROUP_SYNCED, anything, contact: contact, channel: channel)

      described_class.new(contact: contact).perform
    end

    # Answering `sync_group` is not the same as being able to carry it out: an inbox on
    # the session layer that takes group conversations and answers no group commands
    # returns without syncing, and this endpoint would otherwise report success over a
    # roster nobody read.
    it 'refuses a session inbox that cannot manage groups' do
      channel = create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false)
      contact = create(:contact, account: channel.account, group_type: :group, identifier: 'group@g.us')
      create(:contact_inbox, contact: contact, inbox: channel.inbox)
      allow(Whatsapp::Session::Registry).to receive(:capabilities_for).and_return(%w[groups])

      expect { described_class.new(contact: contact, channel: channel).perform }
        .to raise_error(ActionController::BadRequest)
    end

    # And the guard reaches only the providers the split applies to. A legacy provider's
    # own service decides whether it can sync, and asking the descriptor for one would
    # newly refuse this endpoint whenever the installation-wide switch is off.
    it 'leaves a legacy provider to its own service' do
      channel = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false)
      contact = create(:contact, account: channel.account, group_type: :group, identifier: 'group@g.us')
      contact_inbox = create(:contact_inbox, contact: contact, inbox: channel.inbox)
      create(:conversation, account: channel.account, inbox: channel.inbox, contact: contact, contact_inbox: contact_inbox)
      allow(channel).to receive(:sync_group).and_return(true)

      described_class.new(contact: contact, channel: channel).perform

      expect(channel).to have_received(:sync_group)
    end
  end
end
