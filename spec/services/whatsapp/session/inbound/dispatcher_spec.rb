require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::Dispatcher do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:model) { Whatsapp::Session::Model }

  it 'routes every canonical type to a handler or to the ignore list' do
    routed = described_class::HANDLERS.keys + described_class::IGNORED

    expect(model::Events::TYPES - routed).to be_empty
  end

  # The table holds names rather than classes, so a typo would otherwise only surface
  # the day that event arrives. This keeps it a load-time guarantee.
  it 'names a handler that exists for every type it routes' do
    missing = described_class::HANDLERS.values.uniq.reject do |name|
      "Whatsapp::Session::Inbound::Handlers::#{name}".safe_constantize.present?
    end

    expect(missing).to be_empty
  end

  # The window is widest exactly where a backlog is: a stream replay, a job that waited
  # in a queue, a retry that waited out a lock. Without this, events already in flight
  # when an operator converted the inbox kept filing the old provider's chats into it.
  it 'drops an event for an inbox that has since changed provider' do
    inbound = model::InboundMessage.new(id: '3EB0AAAA0001', chat: model::Address.phone('5541999990000'),
                                        from_me: false, content: model::Content::Text.new(body: 'oi'))
    event = model::Event.build(model::Events::MessageReceived.new(message: inbound))
    # The object the worker is holding, loaded while the inbox was still native.
    in_flight = Channel::Whatsapp.find(channel.id)
    channel.update_columns(provider: 'whatsapp_cloud') # rubocop:disable Rails/SkipsModelValidations

    expect(described_class.dispatch(in_flight, event)).to eq(:ignored)
    expect(channel.inbox.messages).to be_empty
  end

  # The move the provider check cannot see: two instances of a hosted provider share a
  # base URL, so re-pointing an inbox leaves the key alone and changes only the token
  # behind it. What arrives afterwards is the traffic of an instance this inbox has left,
  # and filing it here files another WhatsApp account's chats.
  it 'drops an event authenticated for an instance the inbox has left' do
    uazapi = create(:channel_whatsapp, provider: 'uazapi', validate_provider_config: false, sync_templates: false)
    fingerprint = Whatsapp::Session::Registry.instance_fingerprint(uazapi)
    inbound = model::InboundMessage.new(id: '3EB0AAAA0002', chat: model::Address.phone('5541999990000'),
                                        from_me: false, content: model::Content::Text.new(body: 'oi'))
    event = model::Event.build(model::Events::MessageReceived.new(message: inbound))
    uazapi.update_columns(provider_config: uazapi.provider_config.merge('token' => 'another-instance')) # rubocop:disable Rails/SkipsModelValidations

    expect(described_class.dispatch(uazapi, event, instance: fingerprint)).to eq(:ignored)
    expect(uazapi.inbox.messages).to be_empty
  end

  # A session paired with a number the inbox is not configured for is somebody else's
  # WhatsApp account. The logout that removes it is asynchronous and retried, so without
  # this its chats would be filed here in the meantime.
  context 'when the inbox has disowned its session' do
    before do
      # Written the way the state handler writes it: the sentence for the dashboard and
      # the key for code to compare against.
      channel.update_provider_connection!(
        'connection' => 'close', 'error_code' => 'wrong_phone_number',
        'error' => I18n.t('errors.inboxes.channel.provider_connection.wrong_phone_number')
      )
    end

    it 'refuses a message event' do
      inbound = model::InboundMessage.new(id: '3EB0AAAA0001', chat: model::Address.phone('5541999990000'),
                                          from_me: false, content: model::Content::Text.new(body: 'oi'))
      event = model::Event.build(model::Events::MessageReceived.new(message: inbound))

      expect(described_class.dispatch(channel, event)).to eq(:ignored)
      expect(channel.inbox.messages).to be_empty
    end

    it 'still takes connection events, which is how the inbox recovers' do
      event = model::Event.build(model::Events::PairingQr.new(png_data_url: 'data:image/png;base64,AAA'), epoch: 9)

      expect(described_class.dispatch(channel, event)).to eq(:handled)
    end
  end

  # An added type is additive, so it ships on the same protocol major. A frame on a
  # major this build does not read is refused earlier, by the parser.
  it 'ignores a type this build does not know instead of failing the shard' do
    event = model::Event.from_frame({ 'v' => 1, 'type' => 'session.teleported', 'payload' => { 'anything' => true } })

    expect(described_class.dispatch(channel, event)).to eq(:ignored)
  end

  it 'ignores a type the catalog knows but this layer does not act on' do
    event = model::Event.build(model::Events::HistorySync.new(kind: 'recent', progress: 10))

    expect(described_class.dispatch(channel, event)).to eq(:ignored)
  end

  it 'hands the event to the handler of its type' do
    event = model::Event.build(model::Events::SessionState.new(state: 'open'))

    expect(described_class.dispatch(channel, event)).to eq(:handled)
    expect(channel.reload.provider_connection['connection']).to eq('open')
  end
end
