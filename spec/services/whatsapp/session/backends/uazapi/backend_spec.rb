require 'rails_helper'

RSpec.describe Whatsapp::Session::Backends::Uazapi::Backend do
  subject(:backend) { described_class.new(channel) }

  let(:channel) { create(:channel_whatsapp, provider: 'uazapi', validate_provider_config: false, sync_templates: false) }
  let(:model) { Whatsapp::Session::Model }
  let(:commands) { Whatsapp::Session::Model::Commands }
  let(:base) { 'https://uazapi.test' }
  let(:phone) { model::Address.phone('5541999990000') }

  def fixture(name)
    JSON.parse(Rails.root.join("spec/fixtures/whatsapp/session/uazapi/rest/#{name}.json").read)
  end

  def stub_uazapi(method, path, response = {}, status: 200)
    stub_request(method, "#{base}#{path}").to_return(
      status: status, body: response.to_json, headers: { 'Content-Type' => 'application/json' }
    )
  end

  before do
    # Every call resolves its host before it connects, so the test address is answered
    # here rather than left to a name server.
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('uazapi.test').and_return(['93.184.216.34'])

    # The contract examples call one method per declared capability, so every endpoint has
    # to answer something. Each example below overrides the one it is actually about.
    stub_request(:any, /uazapi\.test/).to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'https://example.test/file.jpg').to_return(status: 200, body: 'bytes',
                                                                  headers: { 'Content-Type' => 'image/jpeg' })
    stub_uazapi(:post, '/webhook', fixture('webhook_register'))
    stub_uazapi(:post, '/instance/connect', fixture('instance_connect_qr'))
    stub_uazapi(:get, '/instance/status', fixture('instance_status_connected'))
    stub_uazapi(:post, '/send/text', fixture('send_text'))
  end

  it_behaves_like 'a whatsapp session backend'

  describe 'the config it will accept' do
    it 'needs a URL and a token, and asks the provider for nothing' do
      expect(described_class.validate_config({})).to contain_exactly('base_url', 'token')
      expect(described_class.validate_config('base_url' => 'not a url', 'token' => 'x')).to eq(['base_url'])
      expect(described_class.validate_config('base_url' => base, 'token' => 'x')).to be_empty
    end

    # Whoever administers the account types this address, and every method here sends that
    # account's credentials to it and shows the answer on the dashboard. An address on the
    # deployment's own network would make the inbox form a way of reading services that
    # were never meant to be reachable from it.
    it 'refuses an address inside the deployment' do
      %w[http://localhost:3000 http://localhost.:3000 http://127.0.0.1 http://10.0.0.5:8080
         http://169.254.169.254 http://[::1]:3000 http://uazapi:3333].each do |url|
        expect(described_class.validate_config('base_url' => url, 'token' => 'x')).to eq(['base_url'])
      end
    end

    # A literal with no dot in it is not a single-label name: every IPv6 address looks
    # like one, and refusing them would turn a perfectly public address into a bad config.
    it 'takes a public address written as an IPv6 literal' do
      expect(described_class.validate_config('base_url' => 'https://[2606:4700:4700::1111]', 'token' => 'x')).to be_empty
    end

    # An instance the operator self-hosts next to Chatwoot is the legitimate case, and it
    # is the same switch the media fetch already reads.
    it 'takes one where the operator has opened the private network' do
      with_modified_env SAFE_FETCH_ALLOW_PRIVATE_NETWORK: 'true' do
        expect(described_class.validate_config('base_url' => 'http://uazapi:3333', 'token' => 'x')).to be_empty
      end
    end
  end

  describe 'connecting' do
    # The webhook has to be up before the session is, or the messages that arrive while it
    # opens have nowhere to be delivered.
    it 'registers the webhook first, pointing at this inbox with its own secret' do
      backend.connect(commands::SessionConnect.new(pairing: 'qr'))

      expect(WebMock).to(have_requested(:post, "#{base}/webhook").with do |request|
        body = JSON.parse(request.body)
        body['url'].end_with?("/webhooks/whatsapp/session/uazapi/#{channel.id}/#{channel.provider_config['webhook_verify_token']}") &&
          body['excludeMessages'] == [] && body['enabled'] == true
      end)
    end

    # `/send/*` can accept a message and then time out on the way back, which the sender
    # treats as retryable. The echo of that send is the only thing that says it landed:
    # it carries the track_id this inbox generated, the row gets its source_id from it,
    # and the retry then declines to send a message that already has one. Excluded, the
    # contact reads the same message twice.
    it 'asks for the echoes of its own sends, which are what a lost answer is recovered from' do
      backend.connect(commands::SessionConnect.new(pairing: 'qr'))

      expect(WebMock).to(have_requested(:post, "#{base}/webhook").with do |request|
        JSON.parse(request.body)['excludeMessages'].exclude?('wasSentByApi')
      end)
    end

    it 'answers with the QR the operator has to scan' do
      state = backend.connect(commands::SessionConnect.new(pairing: 'qr'))

      expect(state).to have_attributes(connection: 'connecting')
      expect(state.qr_data_url).to start_with('data:image/png;base64,')
    end

    # A number only goes on the connect when the operator asked for a pairing code:
    # sending one otherwise is what makes the provider skip the QR.
    it 'sends the phone only when pairing by code' do
      backend.connect(commands::SessionConnect.new(pairing: 'qr', phone: '5541999991111'))

      expect(WebMock).to(have_requested(:post, "#{base}/instance/connect").with { |request| request.body.exclude?('5541999991111') })
    end

    it 'sends the phone when pairing by code' do
      backend.connect(commands::SessionConnect.new(pairing: 'code', phone: '5541999991111'))

      expect(WebMock).to have_requested(:post, "#{base}/instance/connect")
        .with(body: hash_including('phone' => '5541999991111'))
    end

    # The provider issues a code only when the connect starts from a disconnected
    # instance: asked for one mid-pairing it answers the state it is already in, with no
    # code at all, and the operator waits on a screen that never fills in.
    it 'ends a pairing already in flight before asking for a code' do
      stub_uazapi(:get, '/instance/status', fixture('instance_status_connecting'))

      backend.connect(commands::SessionConnect.new(pairing: 'code', phone: '5541999991111'))

      expect(WebMock).to have_requested(:post, "#{base}/instance/disconnect")
    end

    # The disconnect settles asynchronously there, and a connect that goes out before it
    # does is answered with the state from before: closed, no code, and a screen that
    # never starts. Observed against a live instance on 22/08/2026.
    it 'waits for the disconnect to take effect before connecting' do
      stub_const("#{described_class}::DISCONNECT_SETTLE_WAIT", 0)
      json = { 'Content-Type' => 'application/json' }
      stub_request(:get, "#{base}/instance/status").to_return(
        { status: 200, body: fixture('instance_status_connecting').to_json, headers: json },
        { status: 200, body: fixture('instance_status_connecting').to_json, headers: json },
        { status: 200, body: fixture('instance_status_disconnected').to_json, headers: json }
      )

      backend.connect(commands::SessionConnect.new(pairing: 'code', phone: '5541999991111'))

      # The one that opened the pairing, then one per wait until the instance is really down.
      expect(WebMock).to have_requested(:get, "#{base}/instance/status").times(3)
    end

    # Disconnecting costs the pairing on this provider, so it is only worth spending on
    # an attempt that is in the way.
    it 'leaves a session that is not pairing alone' do
      stub_uazapi(:get, '/instance/status', fixture('instance_status_disconnected'))

      backend.connect(commands::SessionConnect.new(pairing: 'code', phone: '5541999991111'))

      expect(WebMock).not_to have_requested(:post, "#{base}/instance/disconnect")
    end
  end

  describe 'the connection state' do
    # The provider answers `connecting` to the connect and can report `disconnected` a
    # second later while still serving the same QR, unchanged, for as long as anyone asks.
    # Read literally that empties the pairing screen one second after the operator asked
    # for it, with the code they were about to scan still on offer.
    it 'reads a state still handing out a QR as a pairing, not a closed session' do
      stub_uazapi(:get, '/instance/status',
                  { 'instance' => { 'status' => 'disconnected', 'qrcode' => 'data:image/png;base64,AAA' } })

      expect(backend.fetch_connection_state).to have_attributes(connection: 'connecting',
                                                                qr_data_url: 'data:image/png;base64,AAA')
    end

    it 'reads the same for a code the provider is still offering' do
      stub_uazapi(:get, '/instance/status', { 'instance' => { 'status' => 'disconnected', 'paircode' => 'K7QP-2M4X' } })

      expect(backend.fetch_connection_state).to have_attributes(connection: 'connecting', pairing_code: 'K7QP-2M4X')
    end

    it 'reads a closed session carrying neither as closed' do
      stub_uazapi(:get, '/instance/status', fixture('instance_status_disconnected'))

      expect(backend.fetch_connection_state).to have_attributes(connection: 'close')
    end

    it 'reports the paired number when the session is open' do
      expect(backend.fetch_connection_state).to have_attributes(connection: 'open', phone_number: '5511999990001')
    end

    context 'when the instance is disconnected' do
      before { stub_uazapi(:get, '/instance/status', fixture('instance_status_disconnected')) }

      it 'reports no number, because `owner` keeps the last one it saw' do
        expect(backend.fetch_connection_state).to have_attributes(connection: 'close', phone_number: nil)
      end
    end

    context 'when the phone logged the session out' do
      before { stub_uazapi(:get, '/instance/status', fixture('instance_status_disconnected_after_pairing')) }

      it 'says the pairing itself is gone' do
        expect(backend.fetch_connection_state).to have_attributes(connection: 'close', error: 'logged_out')
      end
    end

    context 'when the instance is waiting to be paired' do
      before { stub_uazapi(:get, '/instance/status', fixture('instance_status_connecting')) }

      it 'carries the code on screen' do
        expect(backend.fetch_connection_state).to have_attributes(connection: 'connecting', phone_number: nil)
        expect(backend.fetch_connection_state.qr_data_url).to be_present
      end
    end
  end

  # There is no unpair endpoint on this provider: `/instance/logout` answers 405.
  describe 'ending a session' do
    before { stub_uazapi(:post, '/instance/disconnect', fixture('instance_disconnect')) }

    it 'logs out by disconnecting' do
      backend.logout

      expect(WebMock).to have_requested(:post, "#{base}/instance/disconnect")
    end

    # Which is not the same as ending the pairing, and the difference decides whether
    # connecting again is a way out of a wrong-number quarantine: here it is not, because
    # the account's credentials stay on the instance and the next connect resumes them.
    it 'does not claim to end a pairing it cannot end' do
      expect(described_class).not_to be_unpairs
    end

    it 'withdraws the webhook when the inbox is torn down' do
      backend.delete_session

      expect(WebMock).to have_requested(:post, "#{base}/webhook").with(body: hash_including('enabled' => false))
      expect(WebMock).to have_requested(:post, "#{base}/instance/disconnect")
    end

    # A conversion that fails on the disconnect is rolled back and the inbox stays on this
    # provider. A webhook withdrawn before finding that out cannot be put back by the
    # rollback: the inbox would go on serving uazapi and silently receive nothing.
    it 'leaves the webhook alone when the disconnect fails' do
      stub_uazapi(:post, '/instance/disconnect', {}, status: 500)

      expect { backend.delete_session }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)
      expect(WebMock).not_to have_requested(:post, "#{base}/webhook").with(body: hash_including('enabled' => false))
    end

    # The inbox is going away either way, and a provider that cannot be reached must not
    # be what keeps a conversion from finishing.
    it 'disconnects even when the webhook cannot be withdrawn' do
      stub_uazapi(:post, '/webhook', {}, status: 500)

      expect { backend.delete_session }.not_to raise_error
      expect(WebMock).to have_requested(:post, "#{base}/instance/disconnect")
    end
  end

  describe 'sending' do
    it 'carries the reserved id as the track id, since the provider assigns its own' do
      result = backend.send_message(
        commands::MessageSend.new(message_id: '3EB0RESERVED', to: phone, content: model::Content::Text.new(body: 'oi'),
                                  client_ref: '3EB0RESERVED')
      )

      expect(WebMock).to have_requested(:post, "#{base}/send/text")
        .with(body: hash_including('number' => '5541999990000', 'text' => 'oi', 'track_id' => '3EB0RESERVED'))
      expect(result.message_id).to eq('3EB00000000000000013')
    end

    it 'addresses a group by its full jid' do
      backend.send_message(
        commands::MessageSend.new(message_id: '3EB0AAAA', to: model::Address.group('120363040000000001'),
                                  content: model::Content::Text.new(body: 'oi'))
      )

      expect(WebMock).to have_requested(:post, "#{base}/send/text")
        .with(body: hash_including('number' => '120363040000000001@g.us'))
    end

    describe 'media' do
      let(:media) do
        model::Content::Media.new(kind: 'audio', mime: 'audio/ogg', voice_note: true, caption: nil,
                                  ref: model::MediaRef.url('https://chatwoot.test/audio.ogg'))
      end

      before { stub_uazapi(:post, '/send/media', fixture('send_media_image')) }

      # A voice note is its own type on WhatsApp; sent as `audio` it renders as a music
      # file instead of the recorded-voice bubble.
      it 'sends a voice note as a push-to-talk, with the url the provider fetches itself' do
        backend.send_message(commands::MessageSend.new(message_id: '3EB0AAAA', to: phone, content: media))

        expect(WebMock).to have_requested(:post, "#{base}/send/media")
          .with(body: hash_including('type' => 'ptt', 'file' => 'https://chatwoot.test/audio.ogg'))
      end
    end

    it 'refuses a content type it cannot send' do
      expect do
        backend.send_message(
          commands::MessageSend.new(message_id: '3EB0AAAA', to: phone,
                                    content: model::Content::Location.new(latitude: 1.0, longitude: 2.0))
        )
      end.to raise_error(Whatsapp::Session::Errors::InvalidPayload)
    end
  end

  # The provider answers an edit with a new message id pointing at the original. Storing
  # that id would rename the message the conversation already knows.
  describe 'editing' do
    before { stub_uazapi(:post, '/message/edit', fixture('message_edit')) }

    it 'keeps the original id' do
      result = backend.edit_message(
        commands::MessageEdit.new(target_id: '3EB0ORIGINAL', to: phone, content: model::Content::Text.new(body: 'nova'))
      )

      expect(WebMock).to have_requested(:post, "#{base}/message/edit")
        .with(body: hash_including('id' => '3EB0ORIGINAL', 'text' => 'nova'))
      expect(result.message_id).to eq('3EB0ORIGINAL')
    end
  end

  describe 'downloading media' do
    let(:command) do
      commands::MessageDownloadMedia.new(
        chat: phone, message_id: '3EB0AAAA',
        ref: model::MediaRef.new(kind: 'uazapi_message', id: '3EB0AAAA', mime: 'audio/ogg; codecs=opus')
      )
    end

    # The media host is resolved before it is connected to, like every other call.
    before do
      allow(Resolv).to receive(:getaddresses).with('free.uazapi.com').and_return(['93.184.216.34'])
      stub_uazapi(:post, '/message/download', fixture('message_download_ptt'))
      stub_request(:get, %r{https://free\.uazapi\.com/files/}).to_return(
        status: 200, body: 'bytes', headers: { 'Content-Type' => 'audio/mpeg' }
      )
    end

    # The URL a media message carries is the encrypted blob on WhatsApp's CDN, so the
    # bytes always take two hops. The provider transcodes on the second one, which is why
    # the mime it answers with wins over the one the message declared.
    it 'asks the provider to decrypt it and reports the type it actually got' do
      payload = backend.download_media(command)

      expect(WebMock).to have_requested(:post, "#{base}/message/download")
        .with(body: hash_including('id' => '3EB0AAAA', 'return_link' => true))
      expect(payload.mime).to eq('audio/mpeg')
    end

    it 'gives up when the provider has no file to hand over' do
      stub_uazapi(:post, '/message/download', { 'mimetype' => 'image/jpeg' })

      expect { backend.download_media(command) }.to raise_error(Whatsapp::Session::Errors::MediaUnavailable)
    end

    # The URL is the provider's to choose, and a hostile or compromised instance could
    # name an address on the deployment's own network to have Rails read something that
    # was never meant to be reachable from it and attach the answer to a conversation.
    it 'refuses to follow the provider onto a private address' do
      allow(Resolv).to receive(:getaddresses).with('free.uazapi.com').and_return(['169.254.169.254'])

      expect { backend.download_media(command) }.to raise_error(Whatsapp::Session::Errors::MediaUnavailable)
      expect(WebMock).not_to have_requested(:get, %r{https://free\.uazapi\.com/files/})
    end

    # SafeFetch names some transport failures and not others: a refused or reset
    # connection comes out as the raw system error, and left alone it escapes this backend
    # as itself and misses the fetch job's retry policy.
    it 'answers a refused media host as the provider being unreachable' do
      stub_request(:get, %r{https://free\.uazapi\.com/files/}).to_raise(Errno::ECONNREFUSED)

      expect { backend.download_media(command) }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)
    end

    # A throttle is the host having a bad minute, not the file being gone: read as gone,
    # the fetch job marks the bubble unsupported instead of coming back for it.
    it 'comes back later when the media host is throttling' do
      stub_request(:get, %r{https://free\.uazapi\.com/files/}).to_return(status: 429, body: 'slow down')

      expect { backend.download_media(command) }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)
    end

    # The provider keeps the decrypted copy for a while and answers 404 once it is gone.
    # Read as the instance being missing it is a retryable outage, and the fetch job would
    # spend its whole ladder on a file that is never coming back and then die without
    # marking the bubble: an empty attachment, and nothing saying why.
    it 'treats a missing file as gone rather than as the instance being down' do
      stub_uazapi(:post, '/message/download', { 'error' => 'message not found' }, status: 404)

      expect { backend.download_media(command) }.to raise_error(Whatsapp::Session::Errors::MediaUnavailable)
    end
  end

  describe 'the account limits' do
    before { stub_uazapi(:get, '/instance/wa_messages_limits', fixture('instance_wa_messages_limits')) }

    it 'answers in the shape the dashboard banner reads' do
      limits = backend.fetch_account_limits

      expect(limits['reachout_time_lock']).to eq('is_active' => false)
      expect(limits['new_chat_cap']).to include('total_quota' => 0, 'used_quota' => 0)
    end
  end

  describe 'checking numbers' do
    before { stub_uazapi(:post, '/chat/check', fixture('chat_check')) }

    it 'reports each number with the address WhatsApp knows it by' do
      checks = backend.check_numbers(commands::ContactCheck.new(phones: %w[553499990002 5500010000000]))

      expect(checks.first).to have_attributes(phone: '553499990002', exists: true)
      expect(checks.first.address).to eq(model::Address.lid('900000100000000'))
      expect(checks.last).to have_attributes(exists: false, address: nil)
    end

    # The captured number is the same either way, so it cannot show which field the phone
    # is read from. This is the ninth-digit case the check exists for: the query carries
    # the digit, the answer does not, and the answer is the one WhatsApp routes to.
    it 'keeps the number WhatsApp answered with, not the one it was asked about' do
      stub_uazapi(:post, '/chat/check', [{ 'isInWhatsapp' => true, 'query' => '5534999990002',
                                           'jid' => '553499990002@s.whatsapp.net', 'lid' => '900000100000000@lid' }])

      check = backend.check_numbers(commands::ContactCheck.new(phones: %w[5534999990002])).first

      expect(check.phone).to eq('553499990002')
      expect(check.address).to eq(model::Address.lid('900000100000000'))
    end
  end

  describe 'groups' do
    it 'reads a created group into the canonical snapshot' do
      stub_uazapi(:post, '/group/create', fixture('group_create'))

      info = backend.create_group(commands::GroupCreate.new(subject: 'captura chatwoot', participants: [phone]))

      expect(info.subject).to eq('captura chatwoot')
      expect(info.group).to eq(model::Address.group('120363000002000000'))
    end

    it 'changes a roster by naming the action and the people' do
      stub_uazapi(:post, '/group/updateParticipants', fixture('group_participants_remove'))

      backend.update_group_participants(
        commands::GroupParticipantsUpdate.new(group: model::Address.group('120363000002000000'), participants: [phone],
                                              action: 'remove')
      )

      expect(WebMock).to have_requested(:post, "#{base}/group/updateParticipants")
        .with(body: hash_including('groupjid' => '120363000002000000@g.us', 'action' => 'remove',
                                   'participants' => ['5541999990000']))
    end

    # The build we captured does not serve `/group/info`, and losing the capability over
    # that would take the whole group sync with it. The listing carries the same snapshot.
    context 'when the provider does not serve /group/info' do
      before do
        stub_uazapi(:post, '/group/info', { 'message' => 'Method Not Allowed.' }, status: 405)
        stub_request(:get, "#{base}/group/list").with(query: { force: true })
                                                .to_return(status: 200, body: fixture('group_list_2').to_json,
                                                           headers: { 'Content-Type' => 'application/json' })
      end

      it 'falls back to finding it in the listing' do
        info = backend.group_info(commands::GroupInfo.new(group: model::Address.group('120363000002000000')))

        expect(info.subject).to eq('captura chatwoot')
      end

      it 'says so when the listing does not have it either' do
        expect do
          backend.group_info(commands::GroupInfo.new(group: model::Address.group('120363000009999999')))
        end.to raise_error(Whatsapp::Session::Errors::SessionNotFound)
      end
    end
  end

  describe 'the small commands' do
    it 'reacts with the emoji, pointing at the message it annotates' do
      stub_uazapi(:post, '/message/react', fixture('message_react'))

      backend.react_message(commands::MessageReact.new(to: phone, target_id: '3EB0TARGET', emoji: '👍'))

      expect(WebMock).to have_requested(:post, "#{base}/message/react")
        .with(body: hash_including('number' => '5541999990000', 'id' => '3EB0TARGET', 'text' => '👍'))
    end

    it 'marks a batch of messages read in one call' do
      stub_uazapi(:post, '/message/markread', fixture('mark_read'))

      backend.mark_read(commands::MessageMarkRead.new(chat: phone, message_ids: %w[3EB0AAAA 3EB0BBBB]))

      expect(WebMock).to have_requested(:post, "#{base}/message/markread")
        .with(body: hash_including('id' => %w[3EB0AAAA 3EB0BBBB]))
    end

    it 'sends a typing indicator that expires on its own' do
      stub_uazapi(:post, '/message/presence', fixture('presence_composing'))

      backend.send_chat_presence(commands::ChatPresence.new(chat: phone, state: 'composing'))

      expect(WebMock).to have_requested(:post, "#{base}/message/presence")
        .with(body: hash_including('presence' => 'composing'))
    end

    # `imagePreview` is the small copy; the full one is what an avatar sync wants.
    it 'reads a profile picture off the chat details' do
      stub_uazapi(:post, '/chat/details', fixture('chat_details'))

      url = backend.profile_picture_url(commands::ContactProfilePicture.new(party: phone, preview: false))

      expect(url).to start_with('https://pps.whatsapp.net/')
    end
  end

  # `/group/invitelink` answers 405 on this provider, and the group snapshot carries no
  # code either, so the capability is not declared and the endpoint is never called.
  it 'refuses to hand out an invite code' do
    expect do
      backend.group_invite_code(commands::GroupInviteGet.new(group: model::Address.group('120363040000000001')))
    end.to raise_error(Whatsapp::Session::Errors::NotSupported)
  end
end
