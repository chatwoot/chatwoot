require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::GroupUpdated do
  subject(:dispatch) do
    with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
      Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)
    end
  end

  let(:channel) do
    create(:channel_whatsapp, provider: 'native', phone_number: '+5541988887777',
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:group) { model::Address.group('120363041234567890') }
  let(:actor) { model::Party.new(phone: '5541999990000', lid: '182736451928374', push_name: 'Ana Souza') }
  let(:changes) { model::Events::GroupUpdated::Changes.new(subject: 'Equipe de Vendas') }
  let(:event) { model::Event.build(model::Events::GroupUpdated.new(group: group, actor: actor, changes: changes)) }

  it 'is ignored while the group capability is off' do
    expect(Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)).to eq(:ignored)
  end

  it 'renames the group and records who did it' do
    expect(dispatch).to eq(:handled)

    group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
    expect(group_contact.name).to eq('Equipe de Vendas')
    activity = group_contact.conversations.last.messages.last
    expect(activity.message_type).to eq('activity')
    expect(activity.content).to include('Equipe de Vendas')
  end

  # A group event may name its author by the other ninth-digit form of the same line.
  # The exact lookup missed the contact and printed the raw number in an activity line
  # that had the person's name available all along.
  context 'when the actor is filed under the other ninth-digit form' do
    let(:actor) { model::Party.new(phone: '5541999990000') }

    before do
      contact = create(:contact, account: channel.account, name: 'Ana Souza', phone_number: '+554199990000')
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: '554199990000')
    end

    it 'blames them by name' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.conversations.last.messages.last.content).to include('Ana Souza')
    end
  end

  # Consolidation re-keys the contact_inbox to the LID, so an actor named only by phone
  # matches no source_id at all and the activity line printed the raw number.
  context 'when the actor is filed under a LID and the event carries only the phone' do
    let(:actor) { model::Party.new(phone: '5541999990000') }

    before do
      contact = create(:contact, account: channel.account, name: 'Ana Souza', phone_number: '+5541999990000')
      create(:contact_inbox, inbox: inbox, contact: contact, source_id: '182736451928374')
    end

    it 'blames them by name' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.conversations.last.messages.last.content).to include('Ana Souza')
    end
  end

  # A promote can be the first thing seen about a participant: the roster sync may never
  # have run, or the person joined before the inbox existed. `update_member_role` only
  # touches a membership that already exists, so the roster kept omitting somebody the
  # event had just confirmed is in the group.
  context 'when a promotion is the first thing seen about the participant' do
    let(:promoted) { model::Party.new(phone: '5541977776666', push_name: 'Bruno') }
    let(:changes) { model::Events::GroupUpdated::Changes.new(promote: [promoted]) }

    it 'files them as an admin instead of doing nothing' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.group_memberships.active.map(&:role)).to include('admin')
    end
  end

  # `changes` is a Data instance and is never blank, so a payload reporting nothing, or
  # nothing this build knows, used to open a group contact, a conversation and a sync
  # broadcast for an event that says nothing.
  context 'when the payload reports no change this build knows' do
    let(:changes) { model::Events::GroupUpdated::Changes.new }

    it 'ignores it instead of opening the group' do
      expect { expect(dispatch).to eq(:ignored) }.not_to change(Contact, :count)
    end
  end

  # A thread the snooze job would reopen for a group this inbox has left can no longer
  # send anything, so leaving has to close that one too.
  context 'when the session itself leaves and its thread is snoozed' do
    let(:changes) { model::Events::GroupUpdated::Changes.new(leave: [model::Party.new(phone: '5541988887777')]) }
    let(:group_contact) do
      create(:contact, account: channel.account, identifier: '120363041234567890@g.us', group_type: :group)
    end
    let!(:snoozed) do
      contact_inbox = create(:contact_inbox, inbox: inbox, contact: group_contact, source_id: '120363041234567890')
      create(:conversation, inbox: inbox, account: channel.account, contact: group_contact,
                            contact_inbox: contact_inbox, group_type: :group, status: :snoozed,
                            snoozed_until: 2.days.from_now)
    end

    it 'resolves it' do
      expect(dispatch).to eq(:handled)

      expect(snoozed.reload.status).to eq('resolved')
    end
  end

  context 'when a setting changed' do
    let(:changes) { model::Events::GroupUpdated::Changes.new(announce: true, locked: false) }

    it 'persists both settings and writes one activity each' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.additional_attributes).to include('announce' => true, 'restrict' => false)
      expect(group_contact.conversations.last.messages.where(message_type: :activity).count).to eq(2)
    end
  end

  # The wire says `admin_add` or `all_member_add`; the dashboard reads the stored value
  # as "may every member add people" and treats anything but `false` as yes. Storing the
  # enum raw therefore shows the exact opposite of the setting the group has.
  context 'when only admins may add people' do
    let(:changes) { model::Events::GroupUpdated::Changes.new(member_add_mode: 'admin_add') }

    it 'stores the setting as the boolean the dashboard reads' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.additional_attributes['member_add_mode']).to be(false)
      expect(group_contact.conversations.last.messages.last.content).to include('only admins to add others')
    end
  end

  context 'when every member may add people' do
    let(:changes) { model::Events::GroupUpdated::Changes.new(member_add_mode: 'all_member_add') }

    it 'stores it as enabled' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.additional_attributes['member_add_mode']).to be(true)
    end
  end

  # WhatsApp reports the inbox's own line without its ninth digit, and it is the phone
  # comparison that decides whether the threads get resolved.
  context 'when the inbox number was removed under its other ninth-digit form' do
    let(:changes) { model::Events::GroupUpdated::Changes.new(leave: [model::Party.new(phone: '554188887777')]) }

    it 'still recognizes the group as left' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.group_left_in?(inbox.id)).to be(true)
    end
  end

  # WhatsApp may name the session's own participant by LID alone, and the contact
  # resolved from that has no phone at all, so comparing numbers can only answer no.
  context 'when the inbox itself is named only by its LID' do
    let(:changes) { model::Events::GroupUpdated::Changes.new(leave: [model::Party.new(lid: '998877665544332')]) }

    before { channel.update_provider_connection!('connection' => 'open', 'lid' => '998877665544332') }

    it 'still recognizes the group as left' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.group_left_in?(inbox.id)).to be(true)
    end
  end

  # The group contact is shared by every inbox of the account that is in the same
  # WhatsApp group, so closing all of its threads, or marking the group left on the
  # contact itself, would end a conversation another number can still use.
  context 'when another inbox of the account is in the same group' do
    let(:changes) { model::Events::GroupUpdated::Changes.new(leave: [model::Party.new(phone: '5541988887777')]) }
    let(:other_inbox) do
      create(:channel_whatsapp, account: channel.account, provider: 'native', phone_number: '+5541977776666',
                                validate_provider_config: false, sync_templates: false).inbox
    end

    it 'closes only its own threads' do
      dispatch
      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      other_contact_inbox = create(:contact_inbox, inbox: other_inbox, contact: group_contact,
                                                   source_id: '120363041234567890')
      other_thread = create(:conversation, contact: group_contact, contact_inbox: other_contact_inbox,
                                           inbox: other_inbox, account: channel.account, status: :open)

      with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
        Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)
      end

      expect(other_thread.reload.status).to eq('open')
    end

    it 'leaves the group only for the inbox that left it' do
      dispatch
      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      create(:contact_inbox, inbox: other_inbox, contact: group_contact, source_id: '120363041234567890')

      with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
        Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)
      end

      expect(group_contact.reload.group_left_in?(inbox.id)).to be(true)
      expect(group_contact.group_left_in?(other_inbox.id)).to be(false)
    end
  end

  context 'when the description was removed' do
    let(:changes) { model::Events::GroupUpdated::Changes.new(description: '') }

    it 'clears it and says so' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.additional_attributes['description']).to be_nil
      expect(group_contact.conversations.last.messages.last.content).to include('removed the group description')
    end
  end

  context 'when participants joined' do
    let(:joined) { model::Party.new(phone: '5541977776666', lid: '55443322', push_name: 'Bruno') }
    let(:changes) { model::Events::GroupUpdated::Changes.new(join: [joined]) }

    it 'adds them as members' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.group_memberships.active.count).to eq(1)
      expect(group_contact.group_memberships.active.first.contact.name).to eq('Bruno')
    end
  end

  context 'when the inbox number itself was removed' do
    let(:changes) { model::Events::GroupUpdated::Changes.new(leave: [model::Party.new(phone: '5541988887777')]) }

    before do
      with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
        Whatsapp::Session::Inbound::Dispatcher.dispatch(
          channel,
          model::Event.build(model::Events::GroupUpdated.new(group: group, actor: actor,
                                                             changes: model::Events::GroupUpdated::Changes.new(subject: 'Equipe')))
        )
      end
    end

    it 'marks the group as left and resolves its threads' do
      expect(dispatch).to eq(:handled)

      group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
      expect(group_contact.group_left_in?(inbox.id)).to be(true)
      expect(group_contact.conversations.where(status: %i[open pending])).to be_empty
    end
  end
end
