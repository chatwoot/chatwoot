require 'rails_helper'

RSpec.describe Whatsapp::Session::Groups::Syncer do
  subject(:sync) { described_class.new(channel: channel, group_contact: group_contact, info: info).perform }

  let(:channel) do
    create(:channel_whatsapp, provider: 'native', phone_number: '+5541988887777',
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:group) { model::Address.group('120363041234567890') }
  let(:group_contact) do
    create(:contact, account: channel.account, identifier: '120363041234567890@g.us', group_type: :group,
                     additional_attributes: stored)
  end
  let(:stored) do
    { 'description' => 'Combinados do time', 'invite_code' => 'OLDCODE', 'owner_pn' => '5541999990000' }
  end
  let(:info) { model::GroupInfo.new(group: group, subject: 'Equipe de Vendas') }

  before { create(:contact_inbox, inbox: inbox, contact: group_contact, source_id: '120363041234567890') }

  it 'brings the name in line with what the provider reports' do
    sync

    expect(group_contact.reload.name).to eq('Equipe de Vendas')
  end

  # A snapshot describes the group as it is now, so a description the group removed has
  # to overwrite the stored one. Dropping the empty value would leave the old text on
  # screen with no way to ever clear it.
  context 'when the group removed its description' do
    let(:info) { model::GroupInfo.new(group: group, subject: 'Equipe de Vendas', description: '') }

    it 'clears it' do
      sync

      expect(group_contact.reload.additional_attributes['description']).to be_nil
    end
  end

  # An absent field is not a removal: the invite code is only readable by an admin, so
  # a sync run by a member must not throw away the code we already have.
  it 'keeps what the snapshot does not describe' do
    sync

    expect(group_contact.reload.additional_attributes).to include(
      'description' => 'Combinados do time', 'invite_code' => 'OLDCODE'
    )
  end

  # WhatsApp refuses every edit of such a group's description, so what the panel owes the
  # operator is the reason rather than a retry. The stored flag is what it reads.
  context 'when the snapshot says the description can no longer be changed' do
    let(:info) { model::GroupInfo.new(group: group, subject: 'Equipe de Vendas', topic_id: 'undefined') }

    it 'records that it is frozen' do
      sync

      expect(group_contact.reload.additional_attributes['description_frozen']).to be(true)
    end
  end

  context 'when the snapshot reports an ordinary description id' do
    let(:stored) { super().merge('description_frozen' => true) }
    let(:info) { model::GroupInfo.new(group: group, subject: 'Equipe de Vendas', topic_id: '3EB0C7' * 3) }

    it 'records that it is not frozen any more' do
      sync

      expect(group_contact.reload.additional_attributes['description_frozen']).to be(false)
    end
  end

  # uazapi never reports the id, and a sync of a group this account also has on a native
  # inbox must not read that silence as "this description can be changed". Writing false
  # here would put the edit back in front of the operator and it would fail forever.
  context 'when the provider does not report the description id' do
    let(:stored) { super().merge('description_frozen' => true) }

    it 'leaves the stored answer alone' do
      sync

      expect(group_contact.reload.additional_attributes['description_frozen']).to be(true)
    end
  end

  # The settings are optional on the wire. A snapshot that does not report one says
  # nothing about it, and a sync must not read that silence as "off".
  context 'when the snapshot reports no settings at all' do
    let(:stored) { super().merge('announce' => true, 'restrict' => true) }

    it 'leaves the stored ones alone' do
      sync

      expect(group_contact.reload.additional_attributes).to include('announce' => true, 'restrict' => true)
    end
  end

  context 'when the snapshot reports a setting off' do
    let(:stored) { super().merge('announce' => true) }
    let(:info) { model::GroupInfo.new(group: group, subject: 'Equipe', announce: false) }

    it 'turns it off' do
      sync

      expect(group_contact.reload.additional_attributes['announce']).to be(false)
    end
  end

  # Only rejoining clears the flag, and only `group.joined` knows that happened. A
  # scheduled sync can still read cached metadata for a group the session left, and
  # clearing it there would put the group actions back for a thread that cannot send.
  context 'when the group was already left and the sync fetched its metadata' do
    subject(:fetched_sync) { described_class.new(channel: channel, group_contact: group_contact).perform }

    let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }

    before do
      group_contact.contact_inboxes.find_by(inbox: inbox).mark_group_left!
      allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend)
    end

    it 'keeps the group marked as left' do
      fetched_sync

      expect(group_contact.reload.group_left_in?(inbox.id)).to be(true)
    end
  end

  # `fetch_info` is a network call and `group_contact` was handed in before it, so the copy the
  # merge reads is already old by the time the write happens. The chat lock around the fetch
  # serialises this group's own events, not the other writers of the column: an avatar sync, a
  # dashboard edit, another inbox. Same shape as the Baileys path, one call earlier.
  context 'when another writer lands during the metadata fetch' do
    subject(:fetched_sync) { described_class.new(channel: channel, group_contact: group_contact).perform }

    let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }

    before do
      allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend)
      allow(backend).to receive(:group_info) do
        Contact.find(group_contact.id).then do |row|
          row.update!(additional_attributes: row.additional_attributes.merge('custom_note' => 'kept'))
        end
        model::GroupInfo.new(group: group, subject: 'Equipe de Vendas')
      end
    end

    it 'does not erase what the other writer stored' do
      fetched_sync

      expect(group_contact.reload.additional_attributes).to include('custom_note' => 'kept')
    end
  end

  # The snapshot comes from `group.joined`, which is the one event that knows the session
  # is back in the group, and it clears the flag for that inbox alone.
  context 'when the group was left and an event brought its metadata back' do
    let(:other_inbox) do
      create(:channel_whatsapp, account: channel.account, provider: 'native', phone_number: '+5541977776666',
                                validate_provider_config: false, sync_templates: false).inbox
    end

    before do
      create(:contact_inbox, inbox: other_inbox, contact: group_contact, source_id: '120363041234567890')
      group_contact.contact_inboxes.each(&:mark_group_left!)
    end

    it 'rejoins this inbox and leaves the other one out of the group' do
      sync

      expect(group_contact.reload.group_left_in?(inbox.id)).to be(false)
      expect(group_contact.group_left_in?(other_inbox.id)).to be(true)
    end
  end

  # `group_last_synced_at` is advanced on every run, and `Contacts::SyncGroupJob` reads
  # it as a 15 minute cooldown for every sync that is not forced, which includes the
  # manual one from the dashboard. A soft sync that skipped the roster would therefore
  # stamp the group as synced and leave a stale member list nothing could refresh.
  # `group.joined` is treated as authoritative because nothing replays what happened
  # while the session was out of the group. A null picture_url could not say whether the
  # group has no photo or the snapshot does not mention one, so a photo removed while the
  # session was away kept the stored image until somebody changed it again.
  context 'when the snapshot says the group has no photo' do
    let(:info) do
      model::GroupInfo.new(group: group, subject: 'Equipe de Vendas', has_picture: false)
    end

    before do
      group_contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                                  content_type: 'image/png')
    end

    it 'clears the stored photo' do
      sync

      expect(group_contact.reload.avatar).not_to be_attached
    end
  end

  # A producer that cannot answer leaves the flag out, and that case has to stay exactly
  # as it was: clearing on silence would drop the photo of every group on every sync.
  context 'when the snapshot does not mention the photo' do
    let(:info) { model::GroupInfo.new(group: group, subject: 'Equipe de Vendas') }

    before do
      group_contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                                  content_type: 'image/png')
    end

    it 'leaves the stored photo alone' do
      sync

      expect(group_contact.reload.avatar).to be_attached
    end
  end

  context 'with a soft sync' do
    subject(:soft_sync) do
      described_class.new(channel: channel, group_contact: group_contact, info: info, soft: true).perform
    end

    let(:info) do
      model::GroupInfo.new(
        group: group, subject: 'Equipe de Vendas', picture_url: 'https://connector.test/group.jpg',
        participants: [
          model::GroupInfo::Participant.new(party: model::Party.new(phone: '5541999990000', push_name: 'Ana'), role: 'admin')
        ]
      )
    end

    it 'still reads the roster' do
      soft_sync

      expect(group_contact.reload.group_memberships.active.count).to eq(1)
    end

    it 'skips the avatar, which is the half an activity ping does not pay for' do
      expect { soft_sync }.not_to have_enqueued_job(Avatar::AvatarFromUrlJob)
    end

    # One provider profile lookup per member without a picture, on every activity hint,
    # for groups that can hold hundreds of them. The Baileys path passes
    # `skip_avatars: soft` for the same reason.
    it 'does not ask the provider for a picture of every member' do
      expect { soft_sync }.not_to have_enqueued_job(Whatsapp::Session::UpdateContactAvatarJob)
    end
  end

  # Swallowing this returns nil, and `Contacts::SyncGroupService` reads that as nothing
  # to apply: it goes on to dispatch CONTACT_GROUP_SYNCED and hand back the untouched
  # contact, reporting a sync that never happened.
  context 'when the provider cannot be reached for the metadata' do
    subject(:fetched_sync) { described_class.new(channel: channel, group_contact: group_contact).perform }

    let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }

    before { allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend) }

    it 'says so instead of reporting an empty sync' do
      allow(backend).to receive(:group_info).and_raise(Whatsapp::Session::Errors::ProviderUnavailable)

      expect { fetched_sync }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)
    end

    it 'gives up quietly on a failure no retry can fix' do
      allow(backend).to receive(:group_info).and_raise(Whatsapp::Session::Errors::NotSupported)

      expect { fetched_sync }.not_to raise_error
    end
  end

  context 'when only admins may add people' do
    let(:info) { model::GroupInfo.new(group: group, subject: 'Equipe', member_add_mode: 'admin_add') }

    it 'stores the setting as the boolean the dashboard reads' do
      sync

      expect(group_contact.reload.additional_attributes['member_add_mode']).to be(false)
    end
  end

  context 'when every member may add people' do
    let(:info) { model::GroupInfo.new(group: group, subject: 'Equipe', member_add_mode: 'all_member_add') }

    it 'stores it as enabled' do
      sync

      expect(group_contact.reload.additional_attributes['member_add_mode']).to be(true)
    end
  end
end
