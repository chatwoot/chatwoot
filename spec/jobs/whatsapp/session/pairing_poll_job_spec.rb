require 'rails_helper'

RSpec.describe Whatsapp::Session::PairingPollJob do
  let(:channel) do
    create(:channel_whatsapp, provider: 'uazapi', phone_number: '+5541988887777',
                              validate_provider_config: false, sync_templates: false)
  end
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }

  before do
    allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend)
    allow(backend.class).to receive(:state_polling?).and_return(true)
  end

  def state(connection, **attrs)
    Whatsapp::Session::Model::ConnectionState.new(connection: connection, **attrs)
  end

  # An inbox re-pointed at another instance of the same provider keeps its key, so the
  # provider fence sees nothing, and this chain runs for minutes. What the old instance
  # answers can name a different phone, which reads as a wrong-number quarantine and ends
  # the session that just replaced it.
  it 'does nothing once the inbox has been pointed at another instance' do
    allow(backend).to receive(:fetch_connection_state).and_return(state('connecting'))
    fingerprint = Whatsapp::Session::Registry.instance_fingerprint(channel)
    channel.update!(provider_config: channel.provider_config.merge('token' => 'another-instance'))

    described_class.perform_now(channel.reload, pairing: 'qr', fence: { instance: fingerprint })

    expect(backend).not_to have_received(:fetch_connection_state)
    expect(channel.reload.provider_connection).to eq({})
  end

  it 'writes the rotated QR and asks for another round while the session is still connecting' do
    allow(backend).to receive(:fetch_connection_state).and_return(state('connecting', qr_data_url: 'data:image/png;base64,ROTATED'))

    expect { described_class.perform_now(channel) }.to have_enqueued_job(described_class)
    expect(channel.reload.provider_connection['qr_data_url']).to eq('data:image/png;base64,ROTATED')
  end

  # `reconnecting` is the provider still working on it, which is when the poll is most
  # needed: the code keeps rotating and the push that would carry it is exactly what
  # this job stands in for.
  it 'keeps polling while the provider reports it is reconnecting' do
    allow(backend).to receive(:fetch_connection_state).and_return(state('reconnecting'))

    expect { described_class.perform_now(channel) }.to have_enqueued_job(described_class)
  end

  it 'stops as soon as the session is paired' do
    allow(backend).to receive(:fetch_connection_state).and_return(state('open', phone_number: '5541988887777'))

    expect { described_class.perform_now(channel) }.not_to have_enqueued_job(described_class)
    expect(channel.reload.provider_connection['connection']).to eq('open')
  end

  # Keeping the token on a settled state leaves this chain looking current: a duplicate
  # delivery of the job would poll a session that already opened, and write
  # `connect_failure` over it if that request happened to fail.
  it 'retires its token once the pairing has settled' do
    channel.update_provider_connection!({ 'connection' => 'connecting', 'pairing_attempt' => 'attempt-1' })
    allow(backend).to receive(:fetch_connection_state).and_return(state('open', phone_number: '5541988887777'))

    described_class.perform_now(channel, pairing: 'qr', fence: { attempt: 'attempt-1' })

    expect(channel.reload.provider_connection).not_to have_key('pairing_attempt')
  end

  # The poll writes state without ever passing through an event handler, so it used to be
  # a way around the ownership check: a missed webhook and a polled `open` was enough to
  # put the inbox back to work on the account the operator scanned by mistake.
  it 'refuses a polled state that reports a number this inbox is not configured for' do
    allow(backend).to receive(:fetch_connection_state).and_return(state('open', phone_number: '5541900001111'))

    described_class.perform_now(channel)

    expect(channel.reload.provider_connection).to include(
      'connection' => 'close', 'error_code' => 'wrong_phone_number'
    )
    expect(Whatsapp::Session::LogoutJob).to have_been_enqueued
  end

  it 'stops at the ceiling instead of polling a pairing nobody completed' do
    allow(backend).to receive(:fetch_connection_state).and_return(state('connecting'))

    expect do
      described_class.perform_now(channel, pairing: 'qr', deadline_at: 10.seconds.from_now)
    end.not_to have_enqueued_job(described_class)

    # And says so, rather than leaving the dashboard on the code that just expired.
    expect(channel.reload.provider_connection).to include(
      'connection' => 'close', 'error_code' => 'pairing_timed_out'
    )
  end

  # A poll sits in the queue for fifteen seconds at a time. An inbox converted in that
  # window is a different provider by the time the job runs, and polling it would write
  # this pairing's outcome onto a session that has nothing to do with it.
  it 'does nothing once the inbox has been converted to another provider' do
    allow(backend).to receive(:fetch_connection_state).and_return(state('connecting'))

    described_class.perform_now(channel, pairing: 'qr', fence: { provider: 'native' })

    expect(backend).not_to have_received(:fetch_connection_state)
    expect(channel.reload.provider_connection).to eq({})
  end

  # A rotated QR, a pairing code or a connecting state arrives without the token, and the
  # writer replaces the whole hash: dropping it there retires the chain that is driving
  # the very screen those events update, and the code stops rotating.
  it 'keeps polling after an event about the same attempt lands' do
    channel.update_provider_connection!({ 'connection' => 'connecting', 'pairing_attempt' => 'attempt-1' })
    Whatsapp::Session::ConnectionStateWriter.new(channel).apply(
      Whatsapp::Session::Model::ConnectionState.new(connection: 'connecting', qr_data_url: 'data:image/png;base64,ROTATED')
    )
    allow(backend).to receive(:fetch_connection_state).and_return(state('connecting'))

    expect { described_class.perform_now(channel.reload, pairing: 'qr', fence: { attempt: 'attempt-1' }) }
      .to have_enqueued_job(described_class)
  end

  # `current?` runs before the provider is asked; the second connect lands after it and
  # before the write. Without the fence this chain's QR replaces the one on screen and
  # puts its own token back on the record, which retires the chain that is actually
  # driving the pairing.
  it 'refuses to write once a newer attempt has claimed the pairing' do
    channel.update_provider_connection!({ 'connection' => 'connecting', 'pairing_attempt' => 'attempt-1' })
    allow(backend).to receive(:fetch_connection_state).and_return(state('connecting', qr_data_url: 'data:image/png;base64,OLDER'))
    allow(Whatsapp::Session::ConnectionStateWriter).to receive(:new).and_wrap_original do |original, argument|
      channel.update_provider_connection!(
        { 'connection' => 'connecting', 'qr_data_url' => 'data:image/png;base64,NEWER', 'pairing_attempt' => 'attempt-2' }
      )
      original.call(argument)
    end

    described_class.perform_now(channel, pairing: 'qr', fence: { attempt: 'attempt-1' })

    expect(channel.reload.provider_connection).to include(
      'qr_data_url' => 'data:image/png;base64,NEWER', 'pairing_attempt' => 'attempt-2'
    )
  end

  # Connecting twice leaves two chains running. The older one keeps its earlier deadline,
  # and without knowing which attempt it belongs to it would time out over the QR the
  # operator is looking at right now.
  it 'lets a newer pairing attempt retire the older chain' do
    channel.update_provider_connection!(
      { 'connection' => 'connecting', 'qr_data_url' => 'data:image/png;base64,NEW', 'pairing_attempt' => 'attempt-2' }
    )
    allow(backend).to receive(:fetch_connection_state).and_return(state('connecting'))

    described_class.perform_now(channel, pairing: 'qr', deadline_at: 10.seconds.from_now, fence: { attempt: 'attempt-1' })

    expect(backend).not_to have_received(:fetch_connection_state)
    expect(channel.reload.provider_connection).to include(
      'connection' => 'connecting', 'qr_data_url' => 'data:image/png;base64,NEW'
    )
  end

  it 'gives a pairing code longer than a QR, since the operator has to type it' do
    expect(described_class::DEADLINES['code']).to be > described_class::DEADLINES['qr']
  end

  # A resume never put a code on screen. Holding it to the QR ceiling cuts the poll two
  # minutes into a reconnection the provider is still working on, and then tells the
  # operator that a code they never saw expired.
  it 'holds a resume to its own ceiling and reports it for what it is' do
    expect(described_class::DEADLINES['resume']).to be > described_class::DEADLINES['qr']

    allow(backend).to receive(:fetch_connection_state).and_return(state('reconnecting'))

    expect do
      described_class.perform_now(channel, pairing: 'resume', deadline_at: 10.seconds.from_now)
    end.not_to have_enqueued_job(described_class)

    expect(channel.reload.provider_connection).to include('connection' => 'close', 'error_code' => 'connect_failure')
  end

  it 'does not poll a backend that pushes its own state' do
    allow(backend.class).to receive(:state_polling?).and_return(false)
    allow(backend).to receive(:fetch_connection_state)

    described_class.perform_now(channel)

    expect(backend).not_to have_received(:fetch_connection_state)
  end

  # Quietly for the job, not for the operator: leaving the state untouched parks the
  # dashboard on a QR that expired minutes ago, waiting for a rotation that never comes.
  it 'says on the screen that the pairing failed instead of leaving a dead QR up' do
    channel.update_provider_connection!({ 'connection' => 'connecting', 'qr_data_url' => 'data:image/png;base64,OLD' })
    allow(backend).to receive(:fetch_connection_state).and_raise(Whatsapp::Session::Errors::ProviderUnavailable)

    expect { described_class.perform_now(channel) }.not_to raise_error

    expect(channel.reload.provider_connection).to include('connection' => 'close', 'error_code' => 'connect_failure')
    expect(channel.provider_connection).not_to have_key('qr_data_url')
  end
end
