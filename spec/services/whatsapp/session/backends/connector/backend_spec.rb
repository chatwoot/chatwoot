require 'rails_helper'

RSpec.describe Whatsapp::Session::Backends::Connector::Backend do
  subject(:backend) { described_class.new(channel) }

  let(:channel) do
    create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false)
  end
  let(:session_id) { channel.provider_config['session_id'] }
  let(:client) { instance_double(Whatsapp::Connector::Client) }
  let(:model) { Whatsapp::Session::Model }

  # What the connector answers, per command type. Anything not listed answers nil, which
  # is enough for the commands whose result is only "it worked".
  let(:results) do
    {
      'session.connect' => { 'connection' => 'connecting', 'qr_data_url' => 'data:image/png;base64,AAA' },
      'session.status' => { 'connection' => 'open', 'reachout_time_lock' => { 'status' => 'UNLOCKED' } },
      'message.send' => { 'message_id' => '3EB0AAAA', 'timestamp' => 1_755_440_000_123 },
      'message.edit' => { 'message_id' => '3EB0BBBB', 'timestamp' => 1_755_440_000_123 },
      'message.react' => { 'message_id' => '3EB0CCCC', 'timestamp' => 1_755_440_000_123 },
      'message.download_media' => { 'kind' => 'url', 'url' => 'https://connector.test/media/abc', 'mime' => 'image/jpeg' },
      'contact.check' => [{ 'phone' => '5541999990000', 'exists' => true, 'address' => { 'kind' => 'phone', 'id' => '5541999990000' } }],
      'contact.profile_picture' => { 'url' => 'https://connector.test/avatar.jpg' },
      'group.create' => { 'group' => { 'kind' => 'group', 'id' => '120363040000000001' }, 'subject' => 'Equipe' },
      'group.info' => { 'group' => { 'kind' => 'group', 'id' => '120363040000000001' }, 'subject' => 'Equipe' },
      'group.invite.get' => { 'code' => 'FAKEINVITE0001' },
      'group.participants.update' => [{ 'address' => { 'kind' => 'phone', 'id' => '5541999990000' }, 'status' => 'success' }],
      'group.join_requests.list' => []
    }
  end

  before do
    allow(Whatsapp::Connector::Client).to receive(:new).with(session_id).and_return(client)
    allow(client).to receive(:publish).and_return('cmd-0001')
    allow(client).to receive(:control).and_return('cmd-0002')
    # A real connector echoes back the id the caller reserved, which is what makes the
    # provider echo of the message recognizable.
    allow(client).to receive(:call) do |command, **|
      result = results[command.class.wire_type]
      result.is_a?(Hash) && result.key?('message_id') ? result.merge('message_id' => command.message_id) : result
    end
    allow(client).to receive(:media_token).with(anything).and_return('media-token')
    allow(Down).to receive(:download).and_return(
      StringIO.new('bytes').tap do |io|
        io.define_singleton_method(:content_type) { 'image/jpeg' }
        io.define_singleton_method(:original_filename) { 'photo.jpg' }
      end
    )
  end

  it_behaves_like 'a whatsapp session backend'

  # The connector fails the command when nothing was carried out. This reaches the same
  # verdict from the rows, so a caller told `ok` and handed a refusal for every
  # participant it named gets the error both controllers already turn into a message an
  # operator reads, rather than a silent success.
  describe 'a participants update the provider refused' do
    let(:command) do
      model::Commands::GroupParticipantsUpdate.new(
        group: model::Address.group('120363040000000001'),
        participants: [model::Address.phone('5541999990000')], action: 'remove'
      )
    end

    it 'raises when every participant was refused' do
      results['group.participants.update'] = [
        { 'address' => { 'kind' => 'phone', 'id' => '5541999990000' }, 'status' => 'failed',
          'code' => 'group_participant_not_allowed' }
      ]

      expect { backend.update_group_participants(command) }
        .to raise_error(Whatsapp::Session::Errors::GroupParticipantNotAllowed)
    end

    # Reporting the participants that were added as not added is a worse answer, and the
    # caller reads the rows to find out which is which.
    it 'hands back a partial refusal rather than failing the command' do
      rows = [
        { 'address' => { 'kind' => 'phone', 'id' => '5541999990000' }, 'status' => 'success', 'code' => nil },
        { 'address' => { 'kind' => 'phone', 'id' => '5541988887777' }, 'status' => 'failed',
          'code' => 'group_participant_not_allowed' }
      ]
      results['group.participants.update'] = rows

      expect(backend.update_group_participants(command)).to eq(rows)
    end

    # An answer with no rows in it refused nobody. Reading it as a refusal for everyone
    # named would fail a command the provider carried out.
    it 'treats an answer with no rows as nothing refused' do
      results['group.participants.update'] = []

      expect { backend.update_group_participants(command) }.not_to raise_error
    end

    # Any other refusal is the connector's to name: it fails the command itself when the
    # code is one it maps, and a code this build does not know must not be read as the
    # one it happens to rescue.
    it 'leaves a refusal it does not recognise alone' do
      results['group.participants.update'] = [
        { 'address' => { 'kind' => 'phone', 'id' => '5541999990000' }, 'status' => 'failed', 'code' => 'internal' }
      ]

      expect { backend.update_group_participants(command) }.not_to raise_error
    end
  end

  it 'declares exactly what the registry advertises for the provider' do
    expect(described_class.capabilities).to eq(Whatsapp::Session::Registry.descriptor('native').capabilities)
  end

  # A number check runs inside a request (opening a conversation, the inbox's number
  # lookup), and the caller already treats a failed check as "keep the typed number". Left
  # on the RPC default it waited 20 s for a session that does not answer, longer than the
  # request itself may run, so the request died with a 500 before the fallback could run.
  it 'gives a number check a ceiling well inside a request' do
    backend.check_numbers(model::Commands::ContactCheck.new(phones: ['5541999990000']))

    expect(client).to have_received(:call)
      .with(an_instance_of(model::Commands::ContactCheck), timeout: be <= 5)
  end

  # A dial asks inside its own budget and hands over what the check may have of it.
  it 'gives a number check the time its caller names' do
    backend.check_numbers(model::Commands::ContactCheck.new(phones: ['5541999990000']), timeout: 3)

    expect(client).to have_received(:call).with(an_instance_of(model::Commands::ContactCheck), timeout: 3)
  end

  # The connector answers `history.request` with `null` once the phone was asked, and
  # refuses one with no anchor; the answer itself comes back as `history.sync`.
  it 'carries a history request to the session and waits for the connector to take it' do
    request = model::Commands::HistoryRequest.new(
      chat: model::Address.phone('5541999990000'), count: 50,
      before: model::Commands::HistoryAnchor.new(id: '3EB0OLDEST', timestamp: 1_755_430_000_000, from_me: false)
    )

    expect(backend.request_history(request)).to be_nil
    expect(client).to have_received(:call).with(request)
    expect(request.to_h).to include('chat' => { 'kind' => 'phone', 'id' => '5541999990000' },
                                    'before' => { 'id' => '3EB0OLDEST', 'timestamp' => 1_755_430_000_000, 'from_me' => false })
  end

  it 'asks for history on every connect and pages only from a message' do
    expect(described_class.history_on_every_connect?).to be(true)
    expect(described_class.history_needs_anchor?).to be(true)
    expect(Whatsapp::Session::Backend.history_on_every_connect?).to be(false)
  end

  it 'refuses to work without the session id the inbox should have generated' do
    channel.update_columns(provider_config: {}) # rubocop:disable Rails/SkipsModelValidations

    expect { described_class.new(channel).logout }.to raise_error(Whatsapp::Session::Errors::InvalidConfig)
  end

  # Nobody owns a session that has never paired, so nobody is reading its command stream
  # and the connect would sit there until its deadline.
  it 'wakes the session on the control stream before it connects' do
    backend.connect(model::Commands::SessionConnect.new(pairing: 'qr'))

    expect(client).to have_received(:control).with(an_instance_of(model::Commands::SessionWake)).ordered
    expect(client).to have_received(:call).ordered
  end

  # A connector reads a session's own command stream only while it is running that
  # session, so a teardown written there for an account nobody has adopted reaches no
  # connector at all and dies when the stream is trimmed -- which is the state an inbox is
  # most often destroyed in. The control stream is read by every instance.
  it 'asks for the session to be deleted on the control stream, where an account nobody runs is still reachable' do
    backend.delete_session

    expect(client).to have_received(:control)
      .with(an_instance_of(model::Commands::SessionDelete), max_runtime: described_class::TEARDOWN_RUNTIME)
    expect(client).not_to have_received(:publish).with(an_instance_of(model::Commands::SessionDelete), any_args)
  end

  # The pairing is what outlives the inbox: a device stays listed on the customer's phone
  # with nothing in Chatwoot corresponding to it. Delivery through the control stream is
  # to some instance rather than to the one running the account, so for a session that is
  # up the unlink rides the owner's own stream and happens at once.
  it 'unlinks the device on the session stream before it asks for the session to be deleted' do
    backend.delete_session

    expect(client).to have_received(:publish)
      .with(an_instance_of(model::Commands::SessionLogout), max_runtime: described_class::TEARDOWN_RUNTIME).ordered
    expect(client).to have_received(:control)
      .with(an_instance_of(model::Commands::SessionDelete), max_runtime: described_class::TEARDOWN_RUNTIME).ordered
  end

  # The connector answers a teardown it could not carry out with `command.failed`, and
  # that event is routed to an inbox by `session_id`: this inbox is being destroyed, so
  # the lookup misses. Short of a teardown the connector never attempted, which is sent
  # again, the event is dropped as an orphan, and what is written here is the last thing
  # about the session anybody can see.
  it 'writes down what it asked for, because the failure has nowhere to be reported' do
    allow(Rails.logger).to receive(:info)

    backend.delete_session

    # The command ids too: they are what ties this line to the connector's own log, which
    # is the only other place a teardown that failed leaves a trace.
    expect(Rails.logger).to have_received(:info).with(/tearing session #{session_id} down.*cmd-0001.*cmd-0002/)
  end

  # What lets a retry of a teardown the connector never attempted tell a disconnect that
  # still stands from a session the operator has paired again since.
  describe 'the note a retried teardown checks' do
    after { Whatsapp::Session::TeardownRetry.withdrawn(session_id) }

    it 'is left by the teardown' do
      backend.delete_session

      expect(Whatsapp::Session::TeardownRetry.wanted?(session_id)).to be(true)
    end

    # The disconnect endpoint answers ProviderUnavailable with a 503 and anything else with
    # a 500, and the client already translates its own Redis failures the same way.
    it 'reports a Redis that is down as the provider being unavailable' do
      allow(Redis::Alfred).to receive(:setex).and_raise(Redis::CannotConnectError)

      expect { backend.delete_session }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)
    end

    it 'outlasts a teardown left pending while the connector is away' do
      backend.delete_session

      expect(Redis::Alfred.ttl(Whatsapp::Session::TeardownRetry.requested_key(session_id)))
        .to be > Whatsapp::Session::TeardownRetry::ATTEMPTS_TTL.to_i
    end

    it 'is withdrawn by asking to connect' do
      backend.delete_session
      backend.connect(model::Commands::SessionConnect.new(pairing: 'qr'))

      expect(Whatsapp::Session::TeardownRetry.wanted?(session_id)).to be(false)
    end
  end

  # A logout is the operator's Disconnect too since it stopped deleting the session
  # (fazer-ai/chatwoot#852), so it has to reach the same places the teardown did.
  describe 'a logout' do
    after { Whatsapp::Session::TeardownRetry.withdrawn(session_id) }

    # A connector reads a session's own stream only while it runs the session, so a logout
    # for one nobody owns -- handed back, or waiting out a resume backoff -- would sit there
    # undelivered. The wake has some instance adopt it, and with `disconnected` stop there.
    it 'has the session adopted, without connecting it, before it asks for the logout' do
      backend.logout

      expect(client).to have_received(:control)
        .with(have_attributes(class: model::Commands::SessionWake, desired: 'disconnected')).ordered
      expect(client).to have_received(:publish)
        .with(an_instance_of(model::Commands::SessionLogout), max_runtime: described_class::TEARDOWN_RUNTIME).ordered
    end

    # One the connector never attempted is sent again only while somebody still wants it,
    # and an inbox that is still here wants it only if this note says so.
    it 'leaves the note a retry of it checks' do
      backend.logout

      expect(Whatsapp::Session::TeardownRetry.wanted?(session_id)).to be(true)
    end
  end

  # Not `call`. This runs inside the transaction that destroys the inbox, and the connector
  # deliberately leaves a teardown pending with no reply while the session is between
  # owners, so there is no answer to wait for.
  it 'asks for the teardown without waiting for an answer' do
    backend.delete_session

    expect(client).not_to have_received(:call)
  end

  it 'turns the connect reply into the connection state the inbox stores' do
    state = backend.connect(model::Commands::SessionConnect.new(pairing: 'qr'))

    expect(state).to be_connecting
    expect(state.qr_data_url).to be_present
  end

  it 'sends a message under an idempotency key built from its reserved id' do
    expect(client).to receive(:call)
      .with(anything, idempotency_key: 'msg:3EB0AAAA', timeout: Whatsapp::Connector::Client::RPC_TIMEOUT)
      .and_return(results['message.send'])

    result = backend.send_message(
      model::Commands::MessageSend.new(message_id: '3EB0AAAA', to: model::Address.phone('5541999990000'),
                                       content: model::Content::Text.new(body: 'oi'))
    )

    expect(result.message_id).to eq('3EB0AAAA')
  end

  # The connector records a group creation before asking WhatsApp, and a retry under the same key collects the
  # group the first attempt made. Retried under a fresh key it makes a second group.
  describe 'a group creation' do
    let(:command) do
      model::Commands::GroupCreate.new(subject: 'Equipe', participants: [model::Address.phone('5541999990000')])
    end
    let(:keys) { [] }
    let(:answers) { [] }

    before do
      allow(Kernel).to receive(:sleep)
      allow(client).to receive(:call).with(an_instance_of(model::Commands::GroupCreate), any_args) do |_, **options|
        keys << options[:idempotency_key]
        answer = answers.shift || results['group.create']
        raise answer if answer.is_a?(Exception)

        answer
      end
    end

    def not_settled = Whatsapp::Session::Errors.build('not_settled', 'group.create: not settled yet')

    it 'goes out once, under an idempotency key' do
      info = backend.create_group(command)

      expect(info.group.id).to eq('120363040000000001')
      expect(keys.size).to eq(1)
      expect(keys.first).to be_present
    end

    it 'asks again under the same key while the outcome is not settled, and hands back the group it made' do
      answers.push(not_settled, not_settled)

      info = backend.create_group(command)

      expect(info.group.id).to eq('120363040000000001')
      expect(keys.size).to eq(3)
      expect(keys.uniq.size).to eq(1)
      expect(Kernel).to have_received(:sleep).twice
    end

    it 'stops after a bounded number of attempts and says the intent is stranded' do
      answers.concat(Array.new(50) { not_settled })
      allow(Rails.logger).to receive(:error)

      expect { backend.create_group(command) }
        .to raise_error(Whatsapp::Session::Errors::Error) { |error|
          expect(error.code).to eq('not_settled')
          expect(error).not_to be_retryable
        }
      expect(keys.size).to be_between(2, 10)
      expect(keys.uniq.size).to eq(1)
      expect(Rails.logger).to have_received(:error).with(/stranded/)
    end

    it 'does not ask again after any other failure' do
      answers.push(Whatsapp::Session::Errors.build('not_connected'))

      expect { backend.create_group(command) }.to raise_error(Whatsapp::Session::Errors::NotConnected)
      expect(keys.size).to eq(1)
    end

    it 'gives each creation a key of its own' do
      backend.create_group(command)
      backend.create_group(command)

      expect(keys.uniq.size).to eq(2)
    end
  end

  # The connector has to fetch the file from this app's storage, encrypt it and upload it
  # to WhatsApp before it can answer, and the default wait covers only a few megabytes of
  # that. A file past it failed on the deadline, was retried, and failed at the same
  # place, which is why the documented cap was never reachable through this client.
  it 'gives a send carrying a file a wait sized from the length the sender declared' do
    expect(client).to receive(:call)
      .with(anything, idempotency_key: 'msg:3EB0BBBB', timeout: Whatsapp::Connector::Client::RPC_TIMEOUT + 25)
      .and_return(results['message.send'])

    backend.send_message(media_send('3EB0BBBB', 25.megabytes))
  end

  # Every other reason to wait is unchanged, so a small file never shortens the wait a
  # text would have had.
  it 'never gives a send less than the default wait' do
    expect(client).to receive(:call)
      .with(anything, idempotency_key: 'msg:3EB0CCCC', timeout: Whatsapp::Connector::Client::RPC_TIMEOUT + 1)
      .and_return(results['message.send'])

    backend.send_message(media_send('3EB0CCCC', 1))
  end

  # A wait this long holds a Redis connection out of the pool and the worker that called
  # it, so a file too big to move inside the ceiling is one this deployment does not send.
  it 'bounds the wait however large the file says it is' do
    expect(client).to receive(:call)
      .with(anything, idempotency_key: 'msg:3EB0DDDD',
                      timeout: described_class::MEDIA_SEND_MAX_TIMEOUT)
      .and_return(results['message.send'])

    backend.send_message(media_send('3EB0DDDD', 10.gigabytes))
  end

  # The contract lets a connection state carry them and this connector fills neither, so
  # answering the read would hand back an empty slice dressed as an answer.
  it 'refuses the account limits rather than answering an empty slice' do
    expect { backend.fetch_account_limits }.to raise_error(Whatsapp::Session::Errors::NotSupported)
  end

  it 'downloads media straight from the URL the event carried' do
    payload = backend.download_media(download_command(model::MediaRef.url('https://connector.test/media/abc', mime: 'image/jpeg')))

    expect(client).not_to have_received(:call)
    expect(Down).to have_received(:download).with(
      'https://connector.test/media/abc', hash_including(headers: hash_including('Authorization' => 'Bearer media-token'))
    )
    expect(payload.mime).to eq('image/jpeg')
  end

  it 'asks the connector to fetch the bytes again when the ref carries no URL' do
    backend.download_media(download_command(model::MediaRef.new(kind: 'connector_blob', id: 'abc')))

    expect(Down).to have_received(:download).with('https://connector.test/media/abc', anything)
  end

  # The connector drops its blobs on a TTL and an LRU quota, so a URL handed out with the
  # event is routinely dead by the time the download job runs. Treating that as terminal
  # marked the message unsupported while the bytes were still one command away.
  it 'asks again for a ref that has already lapsed' do
    lapsed = model::MediaRef.new(kind: 'connector_blob', id: 'abc', url: 'https://connector.test/media/stale',
                                 expires_at: 1.hour.ago.to_i * 1000)

    backend.download_media(download_command(lapsed))

    expect(Down).not_to have_received(:download).with('https://connector.test/media/stale', anything)
    expect(Down).to have_received(:download).with('https://connector.test/media/abc', anything)
  end

  # A refused request is an operational problem, not a missing file, and the two lead to
  # opposite outcomes: the job retries a refusal, while media that is gone marks the
  # message unsupported and never comes back.
  it 'tells a refused media request apart from media that is gone' do
    response = instance_double(Net::HTTPForbidden, code: '403')
    allow(Down).to receive(:download).and_raise(Down::ClientError.new('forbidden', response))

    expect { backend.download_media(download_command(model::MediaRef.url('https://connector.test/media/abc'))) }
      .to raise_error(Whatsapp::Session::Errors::Unauthorized)
  end

  # A blob URL names the instance that downloaded it, and that instance can be replaced
  # before the download job runs. Retrying the dead URL forever left the message without
  # its attachment; asking again reaches whoever holds the session now.
  it 'asks again when the instance serving the blob is no longer there' do
    allow(Down).to receive(:download).with('https://connector.test/media/dead', anything)
                                     .and_raise(Down::ConnectionError, 'connection refused')

    backend.download_media(download_command(model::MediaRef.url('https://connector.test/media/dead')))

    expect(Down).to have_received(:download).with('https://connector.test/media/abc', anything)
  end

  it 'asks again when the blob turns out to be gone mid-flight' do
    allow(Down).to receive(:download).with('https://connector.test/media/stale', anything).and_raise(Down::NotFound, 'gone')
    fresh = model::MediaRef.url('https://connector.test/media/stale', mime: 'image/jpeg').with(expires_at: 1.hour.from_now.to_i * 1000)

    backend.download_media(download_command(fresh))

    expect(client).to have_received(:call).once
    expect(Down).to have_received(:download).with('https://connector.test/media/abc', anything)
  end

  def media_send(message_id, size)
    model::Commands::MessageSend.new(
      message_id: message_id, to: model::Address.phone('5541999990000'),
      content: model::Content::Media.new(
        kind: 'document', mime: 'application/pdf', filename: 'contrato.pdf', size: size,
        ref: model::MediaRef.url('http://rails:3000/rails/active_storage/blobs/proxy/abc', mime: 'application/pdf',
                                                                                           size: size)
      )
    )
  end

  def download_command(ref)
    model::Commands::MessageDownloadMedia.new(chat: model::Address.phone('5541999990000'), message_id: '3EB0AAAA', ref: ref)
  end

  it 'answers fire-and-forget commands without waiting' do
    expect(client).not_to receive(:call)

    backend.mark_read(model::Commands::MessageMarkRead.new(chat: model::Address.phone('5541999990000'), message_ids: ['3EB0AAAA']))
    backend.disconnect
  end

  # --- the ceiling on a published command ------------------------------------------
  #
  # Nobody is waiting on a published command, so the deadline the frame carries is the
  # only limit the connector has for it, and the session's executor is serial: one parked
  # on a socket write is every send behind it parked too.

  # A momentary state that lands late is not late, it is wrong: an `available` applied
  # after the agent went offline flips the account back, and a `composing` applied minutes
  # later is a typing bubble for something nobody is typing.
  it 'bounds the momentary states by how long they are still true' do
    backend.send_chat_presence(model::Commands::ChatPresence.new(chat: model::Address.phone('5541999990000'), state: 'composing'))
    backend.update_presence(model::Commands::PresenceSet.new(state: 'available'))

    expect(client).to have_received(:publish)
      .with(an_instance_of(model::Commands::ChatPresence), timeout: described_class::MOMENTARY_TIMEOUT)
    expect(client).to have_received(:publish)
      .with(an_instance_of(model::Commands::PresenceSet), timeout: described_class::MOMENTARY_TIMEOUT)
  end

  # These three are still right whenever they land, so the only reason to bound them is
  # the executor, and the ceiling has to clear the longest command that can legitimately
  # be ahead of them on the same queue, which is a send carrying a file.
  it 'bounds the deferrable commands by what clears a send carrying a file' do
    backend.mark_read(model::Commands::MessageMarkRead.new(chat: model::Address.phone('5541999990000'), message_ids: ['3EB0AAAA']))
    backend.mark_unread(model::Commands::MessageMarkUnread.new(chat: model::Address.phone('5541999990000'),
                                                               last_message_id: '3EB0AAAA', from_me: false))
    backend.subscribe_presence(model::Commands::PresenceSubscribe.new(party: model::Address.phone('5541999990000')))

    expect(client).to have_received(:publish)
      .with(an_instance_of(model::Commands::MessageMarkRead), timeout: described_class::DEFERRABLE_TIMEOUT)
    expect(client).to have_received(:publish)
      .with(an_instance_of(model::Commands::MessageMarkUnread), timeout: described_class::DEFERRABLE_TIMEOUT)
    expect(client).to have_received(:publish)
      .with(an_instance_of(model::Commands::PresenceSubscribe), timeout: described_class::DEFERRABLE_TIMEOUT)
    expect(described_class::DEFERRABLE_TIMEOUT).to be > described_class::MEDIA_SEND_MAX_TIMEOUT
    # And the two budgets have to stay on the right sides of each other: the whole point of
    # splitting them is that a momentary state expires while a deferrable one is still
    # waiting its turn behind a send.
    expect(described_class::MOMENTARY_TIMEOUT).to be < described_class::DEFERRABLE_TIMEOUT
  end

  # The pairing screen runs on a ceiling of its own, and a code produced after it is a code
  # for a screen the operator is no longer looking at.
  it 'bounds the pairing code request by the attempt that asked for it' do
    backend.request_pairing_code(model::Commands::PairingRequestCode.new(phone: '5541999990000'))

    expect(client).to have_received(:publish)
      .with(an_instance_of(model::Commands::PairingRequestCode), timeout: described_class::PAIRING_TIMEOUT)
  end

  # The teardown takes the ceiling counted from when the work starts, and takes it alone.
  # A deadline is the half it cannot have: it is published precisely so it can sit pending
  # while the session is between owners, and a `session.logout` refused for arriving late
  # leaves a device listed on the customer's phone with nothing here corresponding to it.
  it 'bounds the teardown by how long it may run, never by when it stops being worth running' do
    backend.disconnect
    backend.logout
    backend.delete_session

    ceiling = { max_runtime: described_class::TEARDOWN_RUNTIME }
    expect(client).to have_received(:publish).with(an_instance_of(model::Commands::SessionDisconnect), **ceiling)
    expect(client).to have_received(:publish).with(an_instance_of(model::Commands::SessionLogout), **ceiling).twice
    expect(client).to have_received(:control).with(an_instance_of(model::Commands::SessionDelete), **ceiling)
    # And never the other one, which is the whole reason both fields exist.
    expect(client).not_to have_received(:publish).with(anything, hash_including(:timeout))
    expect(client).not_to have_received(:control).with(anything, hash_including(:timeout))
  end
end
