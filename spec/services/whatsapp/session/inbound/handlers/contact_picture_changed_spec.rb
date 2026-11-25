require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::ContactPictureChanged do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:contact) { create(:contact, account: channel.account, phone_number: '+5541999990000', identifier: '182736451928374@lid') }
  let(:party) { model::Party.new(phone: '5541999990000', lid: '182736451928374') }
  let(:removed) { false }
  let(:event) { model::Event.build(model::Events::ContactPictureChanged.new(party: party, removed: removed)) }

  before { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '182736451928374') }

  it 'drops the stored avatar and asks for the new one' do
    dispatch

    expect(Whatsapp::Session::UpdateContactAvatarJob)
      .to have_been_enqueued.with(contact, inbox, hash_including('phone' => '5541999990000'), force: true)
  end

  # `Avatar::AvatarFromUrlJob` skips a contact synced in the last minute or handed a URL
  # it already fetched, and stamps both markers even on the run it skipped. Purging the
  # avatar up front and then having the download skipped left the contact with no
  # picture and no attempt that would ever fire again.
  context 'when the contact already has an avatar' do
    before do
      contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                            content_type: 'image/png')
      contact.update!(additional_attributes: { 'last_avatar_sync_at' => Time.current.iso8601,
                                               'avatar_url_hash' => 'abc123' })
    end

    it 'keeps it until the replacement can be attached' do
      dispatch

      expect(contact.reload.avatar).to be_attached
    end

    it 'clears the markers that would suppress the download' do
      dispatch

      expect(contact.reload.additional_attributes).not_to include('last_avatar_sync_at', 'avatar_url_hash')
    end
  end

  context 'when the photo was removed' do
    let(:removed) { true }

    it 'does not ask for a replacement' do
      expect(dispatch).to eq(:handled)
      expect(Whatsapp::Session::UpdateContactAvatarJob).not_to have_been_enqueued
    end
  end

  # A contact inbox keyed by LID is invisible to a lookup holding only the phone, which
  # is what the event carries for a contact created before the inbox moved provider.
  context 'when the event carries only the phone' do
    let(:party) { model::Party.new(phone: '5541999990000') }

    it 'still finds the contact behind the LID' do
      expect(dispatch).to eq(:handled)
      expect(Whatsapp::Session::UpdateContactAvatarJob)
        .to have_been_enqueued.with(contact, inbox, hash_including('phone' => '5541999990000'), force: true)
    end
  end

  # The event may carry the other ninth-digit form of the same line, and the contact is
  # stored under whichever one first reached us.
  context 'when the event carries the other ninth-digit form' do
    let(:party) { model::Party.new(phone: '554199990000') }

    it 'still finds the contact' do
      expect(dispatch).to eq(:handled)
      expect(Whatsapp::Session::UpdateContactAvatarJob).to have_been_enqueued
    end
  end

  context 'when nobody here knows the number' do
    let(:party) { model::Party.new(phone: '5541900001111') }

    it 'ignores the event instead of inventing a contact' do
      expect { expect(dispatch).to eq(:ignored) }.not_to change(Contact, :count)
    end
  end
end
