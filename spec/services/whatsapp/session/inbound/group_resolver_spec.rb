require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::GroupResolver do
  subject(:resolve) { described_class.new(inbox: inbox, group: group, sender: sender, subject: 'Equipe de Vendas').perform }

  let(:channel) do
    create(:channel_whatsapp, provider: 'native', phone_number: '+5541988887777',
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:group) { model::Address.group('120363041234567890') }
  let(:sender) { model::Party.new(phone: '5541999990000', lid: '182736451928374', push_name: 'Ana Souza') }

  it 'files the sender as a member of the group' do
    result = resolve

    member = GroupMember.find_by(group_contact: result.group_contact, contact: result.sender_contact)
    expect(member).to have_attributes(role: 'member', is_active: true)
  end

  # A message says who wrote it, never what they are in the group. Writing the default
  # role here demoted an administrator on every message they sent, and `inbox_admin?` is
  # what decides whether this inbox may post in an announce-only group.
  it 'keeps a role a roster sync or a promotion already recorded' do
    first = resolve
    GroupMember.find_by(group_contact: first.group_contact, contact: first.sender_contact).update!(role: :admin)

    result = described_class.new(inbox: inbox, group: group, sender: sender).perform

    expect(GroupMember.find_by(group_contact: result.group_contact, contact: result.sender_contact).role).to eq('admin')
  end

  # A message names the chat, never the group, so the contact is created named after the
  # JID. Nothing else fills that in: the events that carry a subject fire when something
  # happens to the group, and being added to it already happened. Without this the thread
  # is called `120363...` for as long as the group stays quiet.
  it 'asks for the roster of a group it has never synced' do
    with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
      expect { described_class.new(inbox: inbox, group: group, sender: sender).perform }
        .to have_enqueued_job(Contacts::SyncGroupJob)
    end
  end

  # The sync drives the roster read through a conversation and opens one when it finds
  # none. This runs before the caller writes the message, so an immediate job opens a
  # second thread that then sits empty in the chat list beside the real one.
  it 'waits for the caller to have opened the thread' do
    with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
      expect { described_class.new(inbox: inbox, group: group, sender: sender).perform }
        .to have_enqueued_job(Contacts::SyncGroupJob).at(a_value > Time.zone.now)
    end
  end

  # The job carries its own 15 minute cooldown, which covers a burst and not a busy group
  # a day later. Asking once per message would queue a roster read per message.
  it 'does not ask again for a group it already knows' do
    resolve.group_contact.update!(additional_attributes: { 'group_last_synced_at' => Time.zone.now.to_i })

    with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
      expect { described_class.new(inbox: inbox, group: group, sender: sender).perform }
        .not_to have_enqueued_job(Contacts::SyncGroupJob)
    end
  end

  # The sync reads the roster through the session. A provider with no group management
  # answers nothing, and the job would spend a queue slot to find that out per group.
  it 'does not ask a provider that cannot read a roster' do
    allow(channel).to receive(:session_capabilities).and_return(%w[qr_pairing groups])

    expect { described_class.new(inbox: inbox, group: group, sender: sender).perform }
      .not_to have_enqueued_job(Contacts::SyncGroupJob)
  end

  it 'reactivates a member who had left and came back' do
    first = resolve
    GroupMember.find_by(group_contact: first.group_contact, contact: first.sender_contact)
               .update!(role: :admin, is_active: false)

    result = described_class.new(inbox: inbox, group: group, sender: sender).perform

    expect(GroupMember.find_by(group_contact: result.group_contact, contact: result.sender_contact))
      .to have_attributes(role: 'admin', is_active: true)
  end
end
