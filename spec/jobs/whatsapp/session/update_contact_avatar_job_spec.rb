require 'rails_helper'

RSpec.describe Whatsapp::Session::UpdateContactAvatarJob do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }
  let(:model) { Whatsapp::Session::Model }
  let(:contact) { create(:contact, account: channel.account, phone_number: '+5541999990000') }
  let(:party) { model::Party.new(phone: '5541999990000', lid: '182736451928374') }

  before { allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend) }

  # The command declares an Address and is built with `new`, which runs no coercion, so
  # handing it a Party would put the wrong shape on the wire and every backend reading
  # the address would fail on it.
  it 'asks the backend for the picture of an address, not of a party' do
    described_class.perform_now(contact, inbox, party.to_h)

    command = backend.commands_of('contact.profile_picture').first
    expect(command.party).to be_a(model::Address)
    expect(command.party.id).to eq('182736451928374')
    expect(Avatar::AvatarFromUrlJob).to have_been_enqueued
      .with(contact, %r{/avatars/182736451928374\.jpg}, resolved_at: be_present)
  end

  # `retry_on` only sees what escapes `perform`, and a rescue in the method catches the
  # error first: the declared retry never ran, and a forced refresh dropped during a
  # transient outage left the old avatar attached with nothing to ask again.
  it 'lets a transient provider failure out so the retry can see it' do
    allow(backend).to receive(:profile_picture_url).and_raise(Whatsapp::Session::Errors::ProviderUnavailable)

    expect { described_class.new.perform(contact, inbox, party.to_h, force: true) }
      .to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)
  end

  it 'swallows a failure no retry can fix' do
    allow(backend).to receive(:profile_picture_url).and_raise(Whatsapp::Session::Errors::NotSupported)

    expect { described_class.new.perform(contact, inbox, party.to_h, force: true) }.not_to raise_error
  end

  it 'does nothing for a contact that already has one' do
    contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png')

    described_class.perform_now(contact, inbox, party.to_h)

    expect(backend.commands_of('contact.profile_picture')).to be_empty
  end
end
