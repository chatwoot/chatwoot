require 'rails_helper'

RSpec.describe Contacts::SyncGroupJob do
  let(:account) { create(:account) }

  let(:contact) do
    create(:contact, account: account, group_type: :group, identifier: '12345@g.us', additional_attributes: {})
  end

  describe '#perform' do
    it 'calls SyncGroupService when group_last_synced_at is nil' do
      service = instance_double(Contacts::SyncGroupService, perform: contact)
      allow(Contacts::SyncGroupService).to receive(:new).with(contact: contact, soft: false).and_return(service)

      described_class.perform_now(contact)

      expect(Contacts::SyncGroupService).to have_received(:new).with(contact: contact, soft: false)
    end

    it 'calls SyncGroupService when group_last_synced_at is older than 15 minutes' do
      contact.update!(additional_attributes: { 'group_last_synced_at' => 20.minutes.ago.to_i })

      service = instance_double(Contacts::SyncGroupService, perform: contact)
      allow(Contacts::SyncGroupService).to receive(:new).with(contact: contact, soft: false).and_return(service)

      described_class.perform_now(contact)

      expect(Contacts::SyncGroupService).to have_received(:new).with(contact: contact, soft: false)
    end

    it 'skips SyncGroupService when group_last_synced_at is within the last 15 minutes' do
      contact.update!(additional_attributes: { 'group_last_synced_at' => 5.minutes.ago.to_i })

      allow(Contacts::SyncGroupService).to receive(:new)

      described_class.perform_now(contact)

      expect(Contacts::SyncGroupService).not_to have_received(:new)
    end

    it 'calls SyncGroupService when recently synced but force is true' do
      contact.update!(additional_attributes: { 'group_last_synced_at' => 5.minutes.ago.to_i })

      service = instance_double(Contacts::SyncGroupService, perform: contact)
      allow(Contacts::SyncGroupService).to receive(:new).with(contact: contact, soft: false).and_return(service)

      described_class.perform_now(contact, force: true)

      expect(Contacts::SyncGroupService).to have_received(:new).with(contact: contact, soft: false)
    end

    it 'rescues ProviderUnavailableError without re-raising' do
      allow(Contacts::SyncGroupService).to receive(:new).and_raise(
        Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError, 'Provider offline'
      )

      expect { described_class.perform_now(contact) }.not_to raise_error
    end
  end
end
