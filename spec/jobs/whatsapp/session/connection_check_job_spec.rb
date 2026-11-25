require 'rails_helper'

RSpec.describe Whatsapp::Session::ConnectionCheckJob do
  let(:channel) { create(:channel_whatsapp, provider: 'uazapi', sync_templates: false, validate_provider_config: false) }
  let(:base) { channel.provider_config['base_url'] }
  let(:model) { Whatsapp::Session::Model }

  def fixture(name)
    JSON.parse(Rails.root.join("spec/fixtures/whatsapp/session/uazapi/rest/#{name}.json").read)
  end

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('uazapi.test').and_return(['93.184.216.34'])
    stub_request(:get, "#{base}/instance/status").to_return(
      status: 200, body: fixture('instance_status_connected').deep_merge('instance' => { 'owner' => channel.phone_number.delete('+') }).to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    stub_request(:get, "#{base}/instance/wa_messages_limits").to_return(
      status: 200, body: fixture('instance_wa_messages_limits').to_json, headers: { 'Content-Type' => 'application/json' }
    )
    # Pointing the inbox somewhere else lets go of the instance it leaves, which the
    # examples below do mid-request.
    stub_request(:post, "#{base}/webhook").to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
  end

  it 'writes what the provider reports and the limits it only answers when asked' do
    described_class.perform_now(channel)

    expect(channel.reload.provider_connection['connection']).to eq('open')
    expect(channel.provider_connection['reachout_time_lock']).to eq('is_active' => false)
    expect(channel.provider_connection['new_chat_cap']).to include('total_quota' => 0)
  end

  # The banner is replaced wholesale by the frontend and each write is its own cable job,
  # with no order between them: two writes for one poll means the first, still carrying the
  # cap from before it, can arrive last and put a stale banner back. Twice is the floor
  # here, one for the connection and one for both limits together.
  it 'publishes both limits in a single write' do
    allow(channel).to receive(:update_provider_connection!).and_call_original

    described_class.perform_now(channel)

    expect(channel).to have_received(:update_provider_connection!).twice
  end

  # A provider that declares no limits has nothing to answer, and asking it would log a
  # refusal as a failed read on every cycle.
  it 'does not ask for limits a backend does not report' do
    allow(Whatsapp::Session::Backends::Uazapi::Backend).to receive(:supports?).and_call_original
    allow(Whatsapp::Session::Backends::Uazapi::Backend).to receive(:supports?).with('account_limits').and_return(false)

    described_class.perform_now(channel)

    expect(channel.reload.provider_connection['connection']).to eq('open')
    expect(WebMock).not_to have_requested(:get, "#{base}/instance/wa_messages_limits")
  end

  # A provider that cannot be reached is not a session that closed, and writing `close`
  # over a healthy connection would show the operator an outage that is not there.
  it 'leaves the last known state alone when the provider does not answer' do
    Whatsapp::Session::ConnectionStateWriter.new(channel).apply(model::ConnectionState.new(connection: 'open'))
    stub_request(:get, "#{base}/instance/status").to_timeout

    described_class.perform_now(channel)

    expect(channel.reload.provider_connection['connection']).to eq('open')
  end

  # The limits are a banner; the connection is the inbox. One failing must not cost the
  # other.
  it 'still writes the connection when the limits cannot be read' do
    stub_request(:get, "#{base}/instance/wa_messages_limits").to_return(status: 500, body: '{}')

    described_class.perform_now(channel)

    expect(channel.reload.provider_connection['connection']).to eq('open')
  end

  # The limits are sticky: they survive every state update the new provider sends, so one
  # written after a conversion shows the agent the old provider's restrictions until the
  # new one happens to report its own.
  it 'does not write the limits onto an inbox that was converted while it was asking' do
    stub_request(:get, "#{base}/instance/wa_messages_limits").to_return(
      status: 200, body: fixture('instance_wa_messages_limits').deep_merge('reachout_timelock' => { 'active' => true }).to_json,
      headers: { 'Content-Type' => 'application/json' }
    ).with { Channel::Whatsapp.where(id: channel.id).update_all(provider: 'whatsapp_cloud') || true } # rubocop:disable Rails/SkipsModelValidations

    described_class.perform_now(channel)

    expect(channel.reload.provider_connection['reachout_time_lock']).to be_nil
  end

  # A conversion is not the only way the answer stops belonging here: pointed at another
  # instance of the same provider, the key does not change and only the address and the
  # token behind it do, so the provider fence sees nothing. What lands is the old
  # instance's number read against the new inbox, which is the shape of a wrong-number
  # quarantine, and a quarantine ends the session that just replaced it.
  it 'does not write the state of an instance the inbox has been moved off' do
    stub_request(:get, "#{base}/instance/status").to_return(
      status: 200, body: fixture('instance_status_connected').to_json, headers: { 'Content-Type' => 'application/json' }
    ).with { channel.update!(provider_config: channel.provider_config.merge('token' => 'another-instance')) || true }

    described_class.perform_now(channel)

    expect(channel.reload.provider_connection['connection']).to be_nil
  end

  it 'does nothing for an inbox that has left the session layer' do
    channel.update_column(:provider, 'whatsapp_cloud') # rubocop:disable Rails/SkipsModelValidations

    described_class.perform_now(channel)

    expect(WebMock).not_to have_requested(:get, "#{base}/instance/status")
  end

  describe Whatsapp::Session::ConnectionCheckSchedulerJob do
    # A connector session is pushed, not polled: asking it every five minutes would be a
    # round trip for something it already reports.
    let(:native) do
      create(:channel_whatsapp, provider: 'native', sync_templates: false, validate_provider_config: false)
    end

    before do
      [channel, native].each do |whatsapp|
        Whatsapp::Session::ConnectionStateWriter.new(whatsapp).apply(model::ConnectionState.new(connection: 'open'))
      end
    end

    it 'checks only the providers that have to be asked' do
      expect { described_class.perform_now }
        .to have_enqueued_job(Whatsapp::Session::ConnectionCheckJob).with(channel).exactly(:once)
    end

    it 'leaves a session that is not up alone' do
      Whatsapp::Session::ConnectionStateWriter.new(channel).apply(model::ConnectionState.new(connection: 'close'))

      expect { described_class.perform_now }.not_to have_enqueued_job(Whatsapp::Session::ConnectionCheckJob)
    end

    # A poll that lands mid-reconnect writes `connecting`, and nothing but the next poll
    # would ever write `open` over it on an instance that reconnects on its own.
    it 'brings a session caught mid-reconnect back to open once the provider confirms it' do
      Whatsapp::Session::ConnectionStateWriter.new(channel).apply(model::ConnectionState.new(connection: 'connecting'))

      perform_enqueued_jobs { described_class.perform_now }

      expect(channel.reload.provider_connection['connection']).to eq('open')
    end
  end
end
