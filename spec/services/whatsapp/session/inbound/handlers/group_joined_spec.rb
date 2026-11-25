require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::GroupJoined do
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
  let(:info) do
    model::GroupInfo.new(
      group: group, subject: 'Equipe de Vendas', description: 'Combinados do time',
      participants: [
        model::GroupInfo::Participant.new(party: model::Party.new(phone: '5541999990000', push_name: 'Ana'), role: 'admin'),
        model::GroupInfo::Participant.new(party: model::Party.new(phone: '5541977776666', push_name: 'Bruno'))
      ]
    )
  end
  let(:event) { model::Event.build(model::Events::GroupJoined.new(info: info)) }

  it 'is ignored while the group capability is off' do
    expect(Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)).to eq(:ignored)
  end

  # Nothing replays the picture-change events from while the session was out of the
  # group, so the snapshot this event carries is the only chance to notice the photo
  # changed; the "already attached" guard kept the old one forever.
  context 'when the group already has a stored avatar' do
    let(:info) do
      model::GroupInfo.new(group: group, subject: 'Equipe de Vendas',
                           picture_url: 'https://connector.test/new.jpg')
    end

    before do
      group_contact = create(:contact, account: channel.account, identifier: '120363041234567890@g.us',
                                       group_type: :group,
                                       additional_attributes: { 'avatar_url_hash' => 'old', 'last_avatar_sync_at' => Time.current.iso8601 })
      create(:contact_inbox, inbox: inbox, contact: group_contact, source_id: '120363041234567890')
      group_contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                                  content_type: 'image/png')
    end

    it 'asks for the picture the snapshot reports' do
      dispatch

      expect(Avatar::AvatarFromUrlJob).to have_been_enqueued
        .with(anything, 'https://connector.test/new.jpg', resolved_at: be_present)
    end

    it 'clears the markers that would suppress the download' do
      dispatch

      expect(inbox.contacts.find_by(identifier: '120363041234567890@g.us').additional_attributes)
        .not_to include('avatar_url_hash', 'last_avatar_sync_at')
    end
  end

  it 'opens the group with its members and its metadata' do
    expect(dispatch).to eq(:handled)

    group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
    expect(group_contact.name).to eq('Equipe de Vendas')
    expect(group_contact.additional_attributes['description']).to eq('Combinados do time')
    expect(group_contact.group_memberships.active.count).to eq(2)
    expect(group_contact.conversations).to be_present
  end

  # This event creates no message, so nothing else moves the thread off resolved: an
  # inbox that locks to a single conversation handed back the resolved thread of the
  # group it was in before, and the rejoined group sat there looking closed.
  context 'when the group was left and its only thread was resolved' do
    let(:group_contact) do
      create(:contact, account: channel.account, identifier: '120363041234567890@g.us', group_type: :group)
    end
    let!(:resolved) do
      contact_inbox = create(:contact_inbox, inbox: inbox, contact: group_contact, source_id: '120363041234567890')
      create(:conversation, inbox: inbox, account: channel.account, contact: group_contact,
                            contact_inbox: contact_inbox, group_type: :group, status: :resolved)
    end

    before { inbox.update!(lock_to_single_conversation: true) }

    it 'reopens it instead of reusing it resolved' do
      expect(dispatch).to eq(:handled)

      expect(resolved.reload.status).to eq('open')
    end

    # The snooze job reopens on its own schedule, and this event creates no message to
    # trigger the reopen a message would: the restored group stayed hidden until then.
    context 'when the thread was snoozed rather than resolved' do
      before { resolved.update!(status: :snoozed, snoozed_until: 2.days.from_now) }

      it 'reopens it as well' do
        expect(dispatch).to eq(:handled)

        expect(resolved.reload.status).to eq('open')
      end
    end
  end

  # An ordinary contact update does not carry `group_members`, so without this an open
  # dashboard keeps showing the roster (and the admin rights) the group had before.
  it 'broadcasts the roster it just synced' do
    channel
    allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
    expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
      Events::Types::CONTACT_GROUP_SYNCED, anything, hash_including(:contact)
    ).at_least(:once)

    dispatch
  end
end
