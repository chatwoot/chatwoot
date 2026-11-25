require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Handlers::ConnectionState do
  subject(:dispatch) { Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event) }

  let(:channel) do
    create(:channel_whatsapp, provider: 'native', phone_number: '+5541988887777',
                              validate_provider_config: false, sync_templates: false)
  end
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }
  let(:model) { Whatsapp::Session::Model }
  let(:event) { model::Event.build(model::Events::SessionState.new(state: 'open', phone: '5541988887777'), epoch: 2) }

  before { allow(channel).to receive(:provider_service).and_return(backend) }

  it 'writes the connection the provider reports' do
    expect(dispatch).to eq(:handled)

    expect(channel.reload.provider_connection).to include('connection' => 'open', 'phone_number' => '5541988887777', 'epoch' => 2)
  end

  it 'keeps the QR of a pairing event' do
    event = model::Event.build(model::Events::PairingQr.new(png_data_url: 'data:image/png;base64,AAA'), epoch: 1)
    described_class.new(channel: channel, event: event).perform

    expect(channel.reload.provider_connection).to include('connection' => 'connecting', 'qr_data_url' => 'data:image/png;base64,AAA')
  end

  # The wire carries a key and the writer stores the sentence, because an Action Cable
  # broadcast has no single reader whose locale could be used on read.
  it 'turns a session that died into the sentence the dashboard renders' do
    event = model::Event.build(model::Events::SessionLoggedOut.new(reason: 'device_removed'), epoch: 3)
    described_class.new(channel: channel, event: event).perform

    expect(channel.reload.provider_connection).to include(
      'connection' => 'close', 'error' => I18n.t('errors.inboxes.channel.provider_connection.logged_out')
    )
  end

  # The connector already tells the two apart and says which. Collapsing them sends an
  # agent who just clicked disconnect to go look at a phone that did nothing, and leaves
  # an operator who really was unlinked on the phone with no idea where it happened.
  it 'says the disconnect came from here when it was asked for from here' do
    event = model::Event.build(model::Events::SessionLoggedOut.new(reason: 'logout_requested'), epoch: 3)
    described_class.new(channel: channel, event: event).perform

    expect(channel.reload.provider_connection).to include(
      'connection' => 'close', 'error_code' => 'logged_out_by_request',
      'error' => I18n.t('errors.inboxes.channel.provider_connection.logged_out_by_request')
    )
  end

  # Both are the end of a pairing, not a connection that may come back. Left out of that
  # list the number stays on the channel, and the next connect tries to resume credentials
  # WhatsApp has already thrown away instead of asking for a fresh QR.
  it 'forgets the number a requested logout ended' do
    model::Event.build(model::Events::SessionState.new(state: 'open', phone: '+5541988887777'), epoch: 3).then do |opened|
      described_class.new(channel: channel, event: opened).perform
    end
    event = model::Event.build(model::Events::SessionLoggedOut.new(reason: 'logout_requested'), epoch: 4)
    described_class.new(channel: channel, event: event).perform

    expect(channel.reload.provider_connection).not_to include('phone_number')
  end

  # Most pairings that go nowhere end this way, and it is not a failure of anything: the
  # code ran out because nobody scanned it, which the person looking at the screen is the
  # one who knows. Reported in red it reads as a broken connection, and the operator goes
  # looking for one. Closed with no sentence, the QR goes away and the button comes back.
  it 'closes without a word when nobody completed the pairing in time' do
    event = model::Event.build(model::Events::PairingError.new(reason: 'timeout', message: 'ran out'), epoch: 3)
    described_class.new(channel: channel, event: event).perform

    expect(channel.reload.provider_connection).to include('connection' => 'close')
    expect(channel.provider_connection).not_to have_key('error')
  end

  it 'closes without a word on the closing state that follows it' do
    event = model::Event.build(model::Events::SessionState.new(state: 'close', reason: 'pairing_timeout'), epoch: 3)
    described_class.new(channel: channel, event: event).perform

    expect(channel.reload.provider_connection).not_to have_key('error')
  end

  # These the operator can act on, and could not before: every pairing failure was
  # reported as `connect_failure`, which says WhatsApp refused the connection and that
  # retries continue on their own. Neither is true of a number WhatsApp will not send a
  # code to, and there is nothing to act on in the sentence either.
  it 'names what actually went wrong when a pairing fails' do
    event = model::Event.build(model::Events::PairingError.new(reason: 'code_refused', message: 'refused'), epoch: 3)
    described_class.new(channel: channel, event: event).perform

    expect(channel.reload.provider_connection).to include(
      'connection' => 'close', 'error_code' => 'pairing_code_refused',
      'error' => I18n.t('errors.inboxes.channel.provider_connection.pairing_code_refused')
    )
  end

  # The dispatcher looks before the handler runs, and this lands in between: the operator
  # saved new credentials while the event was on its way to the write. The instance travels
  # with the event so the writer can compare it inside the row lock, which is the only place
  # the comparison is atomic. What it keeps out is the old instance's number, read against
  # the new inbox as a wrong-number quarantine that would end the session replacing it.
  it 'refuses a state whose instance the inbox left while the event was in flight' do
    uazapi = create(:channel_whatsapp, provider: 'uazapi', phone_number: '+5541988886666',
                                       validate_provider_config: false, sync_templates: false)
    paired = model::Event.build(model::Events::SessionState.new(state: 'open', phone: '5541988886666'), epoch: 2)
    fingerprint = Whatsapp::Session::Registry.instance_fingerprint(uazapi)
    allow(Whatsapp::Session::ConnectionStateWriter).to receive(:new).and_wrap_original do |original, argument|
      uazapi.update_columns(provider_config: uazapi.provider_config.merge('token' => 'another')) # rubocop:disable Rails/SkipsModelValidations
      original.call(argument)
    end

    result = described_class.new(channel: uazapi, event: paired, instance: fingerprint).perform

    expect(result).to eq(:ignored)
    expect(uazapi.reload.provider_connection).to eq({})
  end

  it 'discards an event from a previous owner of the session' do
    dispatch
    stale = model::Event.build(model::Events::SessionState.new(state: 'close'), epoch: 1)

    expect(described_class.new(channel: channel, event: stale).perform).to eq(:ignored)
    expect(channel.reload.provider_connection['connection']).to eq('open')
  end

  context 'when a different number was paired' do
    let(:event) { model::Event.build(model::Events::PairingSuccess.new(phone: '5541900001111', lid: '99887766'), epoch: 1) }

    it 'refuses the session and says why' do
      expect(dispatch).to eq(:handled)

      # Both: the sentence is what the dashboard renders, and the key is what the
      # dispatcher compares against to keep the wrong account's chats out. Comparing the
      # sentence would fail open under another locale or a reworded translation.
      expect(channel.reload.provider_connection).to include(
        'connection' => 'close', 'error_code' => 'wrong_phone_number',
        'error' => I18n.t('errors.inboxes.channel.provider_connection.wrong_phone_number')
      )
      expect(Whatsapp::Session::LogoutJob).to have_been_enqueued.with(channel)
    end
  end

  # The inbox is configured as +55 41 98888-7777 and WhatsApp reports the same line as
  # 554188887777, because Brazilian numbers registered before the ninth digit are still
  # addressed without it. Comparing the raw digits would log the operator out of the
  # very number they configured.
  context 'when the paired number is the configured one without its ninth digit' do
    let(:event) { model::Event.build(model::Events::PairingSuccess.new(phone: '554188887777', lid: '99887766'), epoch: 1) }

    it 'accepts the session' do
      expect(dispatch).to eq(:handled)

      expect(channel.reload.provider_connection['error']).to be_blank
      expect(backend.commands_of('session.logout')).to be_empty
    end
  end

  it 'keeps the account limits a poll wrote while the state changes' do
    channel.update_provider_connection!({ 'connection' => 'open', 'reachout_time_lock' => { 'until' => 123 } })
    described_class.new(channel: channel, event: model::Event.build(model::Events::SessionState.new(state: 'connecting'))).perform

    expect(channel.reload.provider_connection).to include('connection' => 'connecting', 'reachout_time_lock' => { 'until' => 123 })
  end

  # `pairing.success` is not the only event that names the paired number. One already
  # queued behind it, or one arriving because the logout failed, used to be accepted on
  # its own and put the inbox back to work on somebody else's WhatsApp account.
  context 'when a session state reports a number the inbox is not configured for' do
    let(:event) do
      model::Event.build(
        model::Events::SessionState.new(state: 'open', phone: '5541900001111'), epoch: 5
      )
    end

    it 'closes the inbox instead of opening it' do
      Whatsapp::Session::Inbound::Dispatcher.dispatch(channel, event)

      expect(channel.reload.provider_connection).to include(
        'connection' => 'close', 'error' => I18n.t('errors.inboxes.channel.provider_connection.wrong_phone_number')
      )
    end
  end

  # `session.state` only requires `state`, so a live session can report itself without
  # naming whose account it is. Accepting one of those while the logout that removes the
  # wrong account is still being retried would clear the quarantine and let the dispatcher
  # file that account's chats here again.
  context 'when a state names no number while the inbox is disowned' do
    before do
      channel.update_provider_connection!(
        { 'connection' => 'close', 'error_code' => 'wrong_phone_number', 'epoch' => 5 }
      )
    end

    it 'keeps the inbox closed on the wrong number' do
      described_class.new(
        channel: channel, event: model::Event.build(model::Events::SessionState.new(state: 'open'), epoch: 5)
      ).perform

      expect(channel.reload.provider_connection).to include(
        'connection' => 'close', 'error_code' => 'wrong_phone_number'
      )
    end

    it 'keeps refusing the wrong account\'s messages' do
      described_class.new(
        channel: channel, event: model::Event.build(model::Events::SessionState.new(state: 'open'), epoch: 5)
      ).perform

      message = model::Event.build(
        model::Events::MessageReceived.new(
          message: model::InboundMessage.new(
            id: '3EB0AAA', chat: model::Address.new(kind: 'phone', id: '5541900001111'),
            sender: model::Party.new(phone: '5541900001111'), from_me: false, timestamp: 1_755_440_000,
            content: model::Content::Text.new(body: 'hi')
          )
        ), epoch: 5
      )

      expect(Whatsapp::Session::Inbound::Dispatcher.dispatch(channel.reload, message)).to eq(:ignored)
    end

    it 'lifts the quarantine once a state names the configured number' do
      described_class.new(
        channel: channel,
        event: model::Event.build(model::Events::SessionState.new(state: 'open', phone: '5541988887777'), epoch: 5)
      ).perform

      expect(channel.reload.provider_connection).to include('connection' => 'open')
      expect(channel.provider_connection).not_to have_key('error_code')
    end
  end

  # The connector took the socket down to dial again through the proxy the operator just
  # saved, and it comes back within the same connect. Nothing failed: written with a
  # sentence, the modal would show it in red with the button to pair again.
  it 'shows a proxy change as a reconnect, with no error' do
    allow(Rails.logger).to receive(:warn)
    event = model::Event.build(model::Events::SessionState.new(state: 'reconnecting', reason: 'proxy_changed'), epoch: 3)
    described_class.new(channel: channel, event: event).perform

    expect(channel.reload.provider_connection).to include('connection' => 'reconnecting', 'rerouting' => true)
    expect(channel.provider_connection).not_to have_key('error')
    expect(channel.provider_connection).not_to have_key('error_code')
    expect(Rails.logger).not_to have_received(:warn).with(/proxy_changed/)
  end

  # The flag belongs to the reconnect it arrived with: the state after it replaces the
  # whole record, and an outage that follows must not read as a deliberate reconnect.
  it 'drops the reroute once the next state arrives' do
    [
      model::Events::SessionState.new(state: 'reconnecting', reason: 'proxy_changed'),
      model::Events::SessionState.new(state: 'reconnecting', reason: 'proxy_unreachable')
    ].each_with_index do |payload, index|
      described_class.new(channel: channel, event: model::Event.build(payload, epoch: 3 + index)).perform
    end

    expect(channel.reload.provider_connection).not_to have_key('rerouting')
  end

  # The session cannot get out through the proxy, so it stays down rather than going out
  # directly. The proxy is the likely cause and the operator is the one who can fix it.
  %w[reconnecting connecting].each do |state|
    it "names the proxy when a session #{state} cannot get out through it" do
      event = model::Event.build(model::Events::SessionState.new(state: state, reason: 'proxy_unreachable'), epoch: 3)
      described_class.new(channel: channel, event: event).perform

      expect(channel.reload.provider_connection).to include(
        'connection' => state, 'error_code' => 'proxy_unreachable',
        'error' => I18n.t('errors.inboxes.channel.provider_connection.proxy_unreachable')
      )
    end
  end

  it 'has a sentence naming the proxy in every locale the dashboard ships' do
    %i[en pt_BR es].each do |locale|
      key = 'errors.inboxes.channel.provider_connection.proxy_unreachable'
      expect(I18n.exists?(key, locale)).to be(true), "no #{locale} sentence for proxy_unreachable"
      expect(I18n.t(key, locale: locale)).to match(/proxy/i)
    end
  end
end
