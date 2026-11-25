require 'rails_helper'

RSpec.describe Channels::Whatsapp::BaileysUpdateGroupAvatarJob do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
  let(:group_contact) { create(:contact, account: whatsapp_channel.account, identifier: '123456789@g.us') }

  before do
    # group_channel relies on contact_inboxes.first&.inbox&.channel
    create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: group_contact, source_id: '123456789')
  end

  it 'enqueues on the low queue' do
    expect { described_class.perform_later(group_contact) }.to have_enqueued_job(described_class).on_queue('low')
  end

  context 'when the group channel has a provider' do
    let(:provider) { instance_double(Whatsapp::Providers::WhatsappBaileysService, try_update_group_avatar: nil) }

    before do
      # The job loads its own channel instance through the contact's inbox, so the stub
      # has to reach whichever instance that is. `any_instance` cannot: `provider_service`
      # is defined on a module prepended to the channel, and RSpec refuses to stub those.
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).and_return(provider)
    end

    it 'forwards to try_update_group_avatar with force: false by default' do
      described_class.perform_now(group_contact)

      expect(provider).to have_received(:try_update_group_avatar).with(group_contact, force: false)
    end

    it 'forwards force: true when passed' do
      described_class.perform_now(group_contact, force: true)

      expect(provider).to have_received(:try_update_group_avatar).with(group_contact, force: true)
    end
  end

  context 'when the group has no channel' do
    let(:orphan_contact) { create(:contact, account: whatsapp_channel.account, identifier: '999@g.us') }

    it 'returns without raising' do
      expect { described_class.perform_now(orphan_contact) }.not_to raise_error
    end
  end
end
