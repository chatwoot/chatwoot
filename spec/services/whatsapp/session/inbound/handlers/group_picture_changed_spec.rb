require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::GroupPictureChanged do
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
  let(:actor) { model::Party.new(phone: '5541999990000', push_name: 'Ana Souza') }
  let(:removed) { false }
  let(:event) do
    model::Event.build(model::Events::GroupPictureChanged.new(group: group, actor: actor, removed: removed))
  end

  it 'is ignored while the group capability is off' do
    expect(Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)).to eq(:ignored)
  end

  it 'records who changed it and asks for the new image' do
    expect(dispatch).to eq(:handled)

    group_contact = inbox.contacts.find_by(identifier: '120363041234567890@g.us')
    expect(group_contact.conversations.last.messages.last.content).to include('changed the group image')
    # The inbox the event came from, not whichever contact_inbox happens to be first:
    # the same group can be in two inboxes of one account.
    expect(Whatsapp::Session::UpdateGroupAvatarJob).to have_been_enqueued.with(group_contact, force: true, channel: channel)
  end

  # The job returns before purging when the group reports no photo, so asking it to
  # refresh a removed image would leave the old one attached for good.
  context 'when the photo was removed' do
    let(:removed) { true }

    it 'purges instead of refetching' do
      expect(dispatch).to eq(:handled)
      expect(Whatsapp::Session::UpdateGroupAvatarJob).not_to have_been_enqueued
    end
  end

  # The refetch is a provider `group_info`, so on an inbox that takes group conversations
  # and answers no group commands the job would go out, be refused, log a warning and
  # leave the old picture -- once per photo change, for every group, forever.
  it 'does not go looking for the new photo without the group command surface' do
    allow(Whatsapp::Session::Registry).to receive(:capabilities_for).and_return(%w[groups])

    with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
      expect { dispatch }.not_to have_enqueued_job(Whatsapp::Session::UpdateGroupAvatarJob)
    end
  end
end
