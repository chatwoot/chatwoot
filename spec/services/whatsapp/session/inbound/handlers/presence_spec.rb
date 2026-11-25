require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::Presence do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) do
    create(:channel_whatsapp, provider: 'native', provider_config: { 'presence_subscribe' => true },
                              validate_provider_config: false, sync_templates: false)
  end
  let(:inbox) { channel.inbox }
  let(:model) { Whatsapp::Session::Model }
  let(:contact) { create(:contact, account: channel.account, phone_number: '+5541999990000') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '182736451928374') }
  let(:conversation) { create(:conversation, contact: contact, contact_inbox: contact_inbox, inbox: inbox, account: channel.account) }
  let(:sender) { model::Party.new(phone: '5541999990000', lid: '182736451928374') }
  let(:event) do
    model::Event.build(
      model::Events::ChatPresence.new(chat: model::Address.phone('5541999990000'), sender: sender, state: 'composing')
    )
  end

  before { conversation }

  it 'tells the dashboard the contact is typing' do
    expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
      Events::Types::CONVERSATION_TYPING_ON, anything, hash_including(conversation: conversation, user: contact)
    )

    expect(dispatch).to eq(:handled)
  end

  # The event carries whichever ninth-digit form WhatsApp uses, and the contact is
  # stored under whichever one reached us first. An exact match drops the indicator.
  context 'when the event carries the other ninth-digit form' do
    let(:contact) { create(:contact, account: channel.account, phone_number: '+554188887777') }
    let(:event) do
      model::Event.build(
        model::Events::ChatPresence.new(
          chat: model::Address.phone('5541988887777'),
          sender: model::Party.new(phone: '5541988887777'), state: 'composing'
        )
      )
    end

    it 'still reaches the contact' do
      expect(Rails.configuration.dispatcher).to receive(:dispatch).with(
        Events::Types::CONVERSATION_TYPING_ON, anything, hash_including(conversation: conversation, user: contact)
      )

      expect(dispatch).to eq(:handled)
    end
  end

  it 'maps a recording indicator to its own event' do
    event = model::Event.build(
      model::Events::ChatPresence.new(chat: model::Address.phone('5541999990000'), sender: sender, state: 'recording')
    )

    expect(Rails.configuration.dispatcher).to receive(:dispatch).with(Events::Types::CONVERSATION_RECORDING, anything, anything)

    described_class.new(channel: channel, event: event).perform
  end

  it 'stays quiet when the inbox did not subscribe to presence' do
    channel.update!(provider_config: channel.provider_config.merge('presence_subscribe' => false))

    expect(Rails.configuration.dispatcher).not_to receive(:dispatch)
    expect(dispatch).to eq(:ignored)
  end

  it 'ignores a group typing indicator, which has no per-contact place in the UI' do
    event = model::Event.build(
      model::Events::ChatPresence.new(chat: model::Address.group('120363041234567890'), sender: sender, state: 'composing')
    )

    expect(described_class.new(channel: channel, event: event).perform).to eq(:ignored)
  end

  it 'turns typing off when the contact goes offline' do
    event = model::Event.build(model::Events::PresenceUpdate.new(party: sender, state: 'unavailable'))

    expect(Rails.configuration.dispatcher).to receive(:dispatch).with(Events::Types::CONVERSATION_TYPING_OFF, anything, anything)

    described_class.new(channel: channel, event: event).perform
  end
end
