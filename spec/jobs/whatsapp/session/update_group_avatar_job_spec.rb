require 'rails_helper'

RSpec.describe Whatsapp::Session::UpdateGroupAvatarJob do
  let(:channel) do
    create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }
  let(:model) { Whatsapp::Session::Model }
  let(:group_contact) do
    create(:contact, account: channel.account, identifier: '120363041234567890@g.us', group_type: :group)
  end
  let(:info) do
    model::GroupInfo.new(group: model::Address.group('120363041234567890'), subject: 'Equipe',
                         picture_url: 'https://connector.test/group.jpg')
  end

  before do
    create(:contact_inbox, inbox: inbox, contact: group_contact, source_id: '120363041234567890')
    allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend)
    allow(backend).to receive(:group_info).and_return(info)
  end

  it 'asks for the picture of a group that has none' do
    described_class.perform_now(group_contact, channel: channel)

    expect(Avatar::AvatarFromUrlJob).to have_been_enqueued.with(group_contact, info.picture_url, resolved_at: be_present)
  end

  it 'leaves an attached avatar alone when the refresh is not forced' do
    group_contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                                content_type: 'image/png')

    described_class.perform_now(group_contact, channel: channel)

    expect(Avatar::AvatarFromUrlJob).not_to have_been_enqueued
  end

  # A group contact is a Contact, so `Avatar::AvatarFromUrlJob` applies its rate limit
  # and its URL hash to it and stamps both markers even on the run it skipped: a forced
  # refresh within the window was dropped, and so was every later attempt at that URL.
  context 'when the group was synced moments ago' do
    before do
      group_contact.update!(additional_attributes: { 'last_avatar_sync_at' => Time.current.iso8601,
                                                     'avatar_url_hash' => 'abc123' })
    end

    it 'clears the markers that would suppress the forced download' do
      described_class.perform_now(group_contact, force: true, channel: channel)

      expect(group_contact.reload.additional_attributes).not_to include('last_avatar_sync_at', 'avatar_url_hash')
    end

    it 'keeps the stored avatar until the replacement can be attached' do
      group_contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                                  content_type: 'image/png')

      described_class.perform_now(group_contact, force: true, channel: channel)

      expect(group_contact.reload.avatar).to be_attached
    end
  end
end
