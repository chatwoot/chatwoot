require 'rails_helper'

RSpec.describe Whatsapp::Session::Facade do
  subject(:facade) { channel.provider_service }

  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:backend) { Whatsapp::Session::Backends::Fake.new(channel) }
  let(:contact) { create(:contact, account: channel.account, phone_number: '+5541999990000', identifier: '182736451928374@lid') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: '182736451928374') }
  let(:conversation) { create(:conversation, contact: contact, contact_inbox: contact_inbox, inbox: inbox, account: channel.account) }

  before { allow(Whatsapp::Session::Registry).to receive(:backend_for).and_return(backend) }

  it 'is what a session channel answers with' do
    # Named rather than `described_class`, which RSpec captured when this file loaded: a
    # reload replaces the class, the channel builds an instance of the new one, and the
    # identity check fails on a facade that is perfectly correct.
    expect(facade).to be_a(Whatsapp::Session::Facade) # rubocop:disable RSpec/DescribedClass
    expect(channel.session_backend).to eq(backend)
  end

  describe 'pairing by code' do
    it 'connects in code mode and puts the code on the record' do
      channel.request_pairing_code

      expect(backend.last_command).to have_attributes(pairing: 'code', phone: channel.phone_number.delete('+'))
      expect(channel.reload.provider_connection).to include('connection' => 'connecting', 'pairing_code' => 'K7QP-2M4X')
    end

    # The mode is the only difference between the two ways in. Everything the QR path
    # sets up for the screen has to be set up here too, or an operator pairing by code
    # gets a session nobody is watching: no attempt token to order two clicks by, and no
    # poll to notice that the code expired.
    it 'claims the screen and polls, exactly like the QR path' do
      allow(backend.class).to receive(:state_polling?).and_return(true)

      expect { channel.request_pairing_code }.to have_enqueued_job(Whatsapp::Session::PairingPollJob)
        .with(channel, hash_including(pairing: 'code'))
      expect(channel.reload.provider_connection['pairing_attempt']).to be_present
    end

    # The connector answers the connect only after it has published the code, and the
    # event carrying it can be filed while this request is still waiting on that answer.
    # The answer itself carries no code, and written as a whole state it used to clear the
    # one the operator had just been shown (#774).
    context 'when the code arrives as an event before the connect answers' do
      let(:writes) { [] }
      let(:arriving) { Whatsapp::Session::Model::ConnectionState.new(connection: 'connecting', pairing_code: 'XRW6-1299') }
      let(:answer) { Whatsapp::Session::Model::ConnectionState.new(connection: 'connecting') }

      before do
        allow(channel).to receive(:update_provider_connection!).and_wrap_original do |original, payload|
          writes << payload.deep_stringify_keys
          original.call(payload)
        end
        allow(backend).to receive(:connect) do
          Whatsapp::Session::ConnectionStateWriter.new(channel).apply(arriving)
          answer
        end
      end

      it 'keeps the code on the record and on every state written after it' do
        channel.request_pairing_code

        expect(channel.reload.provider_connection).to include('connection' => 'connecting', 'pairing_code' => 'XRW6-1299')
        after_code = writes.drop_while { |payload| payload['pairing_code'].blank? }
        expect(after_code).not_to be_empty
        expect(after_code).to all(include('pairing_code' => 'XRW6-1299'))
      end

      context 'when the event carries a QR instead' do
        let(:arriving) { Whatsapp::Session::Model::ConnectionState.new(connection: 'connecting', qr_data_url: 'data:image/png;base64,QR1') }

        it 'keeps the QR' do
          channel.setup_channel_provider

          expect(channel.reload.provider_connection).to include('qr_data_url' => 'data:image/png;base64,QR1')
        end
      end

      context 'when the answer carries a code of its own' do
        let(:answer) { Whatsapp::Session::Model::ConnectionState.new(connection: 'connecting', pairing_code: 'NEW1-2345') }

        it 'shows the code the answer brought' do
          channel.request_pairing_code

          expect(channel.reload.provider_connection).to include('pairing_code' => 'NEW1-2345')
        end
      end

      context 'when the answer is already paired' do
        let(:answer) { Whatsapp::Session::Model::ConnectionState.new(connection: 'open') }

        it 'leaves no code on a session that is open' do
          channel.request_pairing_code

          expect(channel.reload.provider_connection).to include('connection' => 'open')
          expect(channel.provider_connection).not_to have_key('pairing_code')
        end
      end

      context 'when the answer is a refusal' do
        let(:answer) { Whatsapp::Session::Model::ConnectionState.new(connection: 'close', error: 'connect_failure') }

        it 'leaves the code behind with the attempt it belonged to' do
          channel.request_pairing_code

          expect(channel.reload.provider_connection).to include('connection' => 'close', 'error_code' => 'connect_failure')
          expect(channel.provider_connection).not_to have_key('pairing_code')
        end
      end
    end

    # What the answer keeps is only what this attempt was given: the claim clears the
    # previous attempt's code before the provider is asked.
    it 'does not carry a code from an earlier attempt into a new one' do
      channel.update_provider_connection!('connection' => 'connecting', 'pairing_code' => 'OLD0-0000', 'pairing_attempt' => 'earlier')
      allow(backend).to receive(:connect).and_return(Whatsapp::Session::Model::ConnectionState.new(connection: 'connecting'))

      channel.request_pairing_code

      expect(channel.reload.provider_connection).not_to have_key('pairing_code')
    end

    it 'refuses a provider that does not declare the capability' do
      allow(channel).to receive(:session_capabilities).and_return(%w[qr_pairing])

      expect { channel.request_pairing_code }.to raise_error(Whatsapp::Session::Errors::NotSupported)
      expect(backend.commands).to be_empty
    end
  end

  describe 'read receipts' do
    it 'marks the stored messages read on WhatsApp' do
      message = create(:message, conversation: conversation, inbox: inbox, account: channel.account, source_id: '3EB0AAAA')

      channel.read_messages([message], conversation: conversation)

      expect(backend.last_command.message_ids).to eq(['3EB0AAAA'])
      expect(backend.last_command.chat.id).to eq('182736451928374')
    end

    it 'stays quiet when the inbox turned mark_as_read off' do
      channel.update!(provider_config: channel.provider_config.merge('mark_as_read' => false))
      message = create(:message, conversation: conversation, inbox: inbox, account: channel.account, source_id: '3EB0AAAA')

      channel.read_messages([message], conversation: conversation)

      expect(backend.commands).to be_empty
    end
  end

  it 'maps a typing indicator to the chat presence the provider expects' do
    channel.toggle_typing_status(Events::Types::CONVERSATION_RECORDING, conversation: conversation)

    expect(backend.last_command.state).to eq('recording')
  end

  it 'answers the on_whatsapp check in the shape the contact builder reads' do
    response = channel.on_whatsapp('+5541999990000')

    expect(response).to eq({ 'jid' => '5541999990000@s.whatsapp.net', 'exists' => true })
  end

  # The caller writes these digits to contacts.phone_number, so a LID here would rename
  # the contact after an opaque internal id and then address it at a JID nobody answers.
  it 'answers with the phone even when the provider also knows a LID' do
    allow(backend).to receive(:check_numbers).and_return(
      [Whatsapp::Session::Model::NumberCheck.new(
        phone: '554199990000', exists: true, address: Whatsapp::Session::Model::Address.lid('900000100000000')
      )]
    )

    expect(channel.on_whatsapp('+5541999990000')).to eq({ 'jid' => '554199990000@s.whatsapp.net', 'exists' => true })
  end

  # The factory neutralizes Channel::Whatsapp#sync_templates, so the facade is asked directly.
  it 'has no templates to sync or to send' do
    expect(facade.sync_templates).to be(true)
    expect { channel.send_template('5541999990000', {}) }.to raise_error(Whatsapp::Session::Errors::NotSupported)
  end

  it 'persists the state the connect answered with, which is what carries the QR' do
    channel.setup_channel_provider

    expect(channel.reload.provider_connection).to include('connection' => 'connecting')
    expect(channel.provider_connection['qr_data_url']).to be_present
  end

  it 'starts the pairing poll only for a backend that has to be polled' do
    expect { channel.setup_channel_provider }.not_to have_enqueued_job(Whatsapp::Session::PairingPollJob)

    allow(backend.class).to receive(:state_polling?).and_return(true)

    # The attempt token is generated per connect, so it is matched by shape, not value.
    expect { channel.provider_service.setup_channel_provider }
      .to have_enqueued_job(Whatsapp::Session::PairingPollJob)
      .with(channel, hash_including(pairing: 'qr', fence: hash_including(provider: 'native')))
  end

  # Two connects racing: the operator clicking twice, or a second tab. Whichever provider
  # call answers last would otherwise be the state on screen even when it belongs to the
  # older attempt, and the poll driving the QR the operator is actually looking at would
  # read the record, find somebody else's token and retire itself.
  it 'refuses a connect answer for an attempt the inbox has already moved past' do
    allow(backend).to receive(:connect) do
      # The second click lands while this one is still waiting on the provider.
      channel.update_provider_connection!(
        { 'connection' => 'connecting', 'qr_data_url' => 'data:image/png;base64,NEWER', 'pairing_attempt' => 'attempt-2' }
      )
      Whatsapp::Session::Model::ConnectionState.new(connection: 'connecting', qr_data_url: 'data:image/png;base64,OLDER')
    end

    channel.provider_service.setup_channel_provider

    expect(channel.reload.provider_connection).to include(
      'qr_data_url' => 'data:image/png;base64,NEWER', 'pairing_attempt' => 'attempt-2'
    )
  end

  # The attempt is claimed before the provider is asked, which puts the dashboard on
  # "connecting" straight away. A refusal that left it there parks the operator on a
  # pairing that never started, with no poll running to ever correct it.
  it 'reports a refused connection instead of leaving the claim on screen' do
    allow(backend).to receive(:connect).and_raise(Whatsapp::Session::Errors::ProviderUnavailable)

    expect { channel.setup_channel_provider }.to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)

    expect(channel.reload.provider_connection).to include('connection' => 'close', 'error_code' => 'connect_failure')
  end

  # Two operators, or two tabs: one converts the inbox while the other clicks connect.
  # The facade holds the backend of the provider it was built for, and the record now
  # belongs to another one, so connecting would leave a session behind that no inbox owns
  # and no operator can see.
  it 'does not connect an inbox that was converted while the request was running' do
    facade = channel.provider_service
    channel.update_columns(provider: 'uazapi') # rubocop:disable Rails/SkipsModelValidations

    expect(facade.setup_channel_provider).to be_nil
    expect(backend.commands).to be_empty
    expect(channel.reload.provider_connection).to eq({})
  end

  # The ceiling belongs to the attempt, not to the worker: a QR lives two minutes from
  # the moment the provider issued it, and a queue running ten minutes late would give
  # that dead code two more minutes of polling.
  it 'hands the poll a deadline counted from the connect, not from the worker' do
    allow(backend.class).to receive(:state_polling?).and_return(true)

    expect { channel.setup_channel_provider }.to(
      have_enqueued_job(Whatsapp::Session::PairingPollJob)
        .with { |_channel, options| expect(options[:deadline_at]).to be_within(5.seconds).of(2.minutes.from_now) }
    )
  end

  # A resume answers `open` when the pairing is still good. There is nothing left to poll
  # then, and a chain started over it would look current forever: the first request that
  # failed would write `connect_failure` over a healthy connection.
  it 'starts no poll for a connect that came back already paired' do
    allow(backend.class).to receive(:state_polling?).and_return(true)
    allow(backend).to receive(:connect).and_return(
      Whatsapp::Session::Model::ConnectionState.new(connection: 'open', phone_number: channel.phone_number.delete('+'))
    )

    expect { channel.setup_channel_provider }.not_to have_enqueued_job(Whatsapp::Session::PairingPollJob)

    expect(channel.reload.provider_connection).to include('connection' => 'open')
    expect(channel.provider_connection).not_to have_key('pairing_attempt')
  end

  # The inbound layer keeps an inbox paired with the wrong number quarantined, and no
  # event lifts that on its own: a state that names no number is refused precisely so a
  # pending logout cannot clear it. Connecting again is the operator's way out, so it
  # has to be the thing that clears it, or fixing the configured number changes nothing.
  it 'lifts a wrong-number quarantine when the operator connects again' do
    channel.update_provider_connection!(
      { 'connection' => 'close', 'error_code' => 'wrong_phone_number',
        'error' => I18n.t('errors.inboxes.channel.provider_connection.wrong_phone_number') }
    )

    channel.provider_service.setup_channel_provider

    expect(channel.reload.provider_connection).to include('connection' => 'connecting')
    expect(channel.provider_connection).not_to have_key('error_code')
  end

  # Lifting that marker is what lets the inbound layer file chats again, and the account
  # that was rejected is still on the provider until its logout lands: pairing first and
  # lifting second would file somebody else's messages here for as long as the new QR is
  # on screen. It also stands the asynchronous logout retry down before there is a new
  # session for it to kill.
  it 'ends the wrong account before it lifts the quarantine keeping that account out' do
    channel.update_provider_connection!({ 'connection' => 'close', 'error_code' => 'wrong_phone_number' })

    channel.provider_service.setup_channel_provider

    expect(backend.commands.map { |command| command.class.wire_type }).to eq(%w[session.logout session.connect])
  end

  # The quarantine is the only reason to end a session here. Doing it on every connect
  # would throw away a perfectly good pairing and cost the operator a fresh scan.
  it 'ends nothing when the inbox is not quarantined' do
    channel.setup_channel_provider

    expect(backend.commands_of('session.logout')).to be_empty
  end

  # A logout that only disconnects leaves the account's credentials on the provider, so
  # connecting again resumes the very session that was refused: the marker would be lifted
  # for an account that never left, and its chats would be filed here until the next state
  # quarantined the inbox again. The disconnect is still asked for, because an instance
  # that stops sending takes that account's traffic off this inbox at the source.
  it 'refuses to connect again on a provider that cannot end the pairing' do
    channel.update_provider_connection!({ 'connection' => 'close', 'error_code' => 'wrong_phone_number' })
    allow(backend.class).to receive(:unpairs?).and_return(false)

    expect { channel.provider_service.setup_channel_provider }
      .to raise_error(Whatsapp::Session::Errors::NotSupported, I18n.t('errors.inboxes.channel.cannot_unpair'))

    expect(backend.commands_of('session.logout')).not_to be_empty
    expect(backend.commands_of('session.connect')).to be_empty
    expect(channel.reload.provider_connection).to include('error_code' => 'wrong_phone_number')
  end

  it 'leaves the inbox quarantined when the wrong account cannot be ended' do
    channel.update_provider_connection!({ 'connection' => 'close', 'error_code' => 'wrong_phone_number' })
    allow(backend).to receive(:logout).and_raise(Whatsapp::Session::Errors::ProviderUnavailable)

    expect { channel.provider_service.setup_channel_provider }
      .to raise_error(Whatsapp::Session::Errors::ProviderUnavailable)

    expect(channel.reload.provider_connection).to include('error_code' => 'wrong_phone_number')
    expect(backend.commands_of('session.connect')).to be_empty
  end

  # `Channel::Whatsapp` used to skip these by asking `respond_to?`, which the facade
  # makes true for every provider. The capability is what decides now, and an
  # unsupported one is skipped rather than raised: these run inside listeners, and a
  # listener that raises takes the event it was handling down with it.
  describe 'background synchronization a backend may not support' do
    before { allow(channel).to receive(:session_capabilities).and_return(%w[groups revoke]) }

    it 'skips marking a conversation unread' do
      message = create(:message, conversation: conversation, inbox: inbox, account: channel.account, source_id: '3EB0AAAA')

      expect { channel.unread_conversation(conversation.reload) }.not_to raise_error
      expect(backend.commands).to be_empty
      expect(message).to be_present
    end

    it 'skips read receipts, typing and presence' do
      message = create(:message, conversation: conversation, inbox: inbox, account: channel.account, source_id: '3EB0AAAA')

      channel.read_messages([message], conversation: conversation)
      channel.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, conversation: conversation)
      channel.update_presence('available')

      expect(backend.commands).to be_empty
    end
  end

  # A receipt on WhatsApp is addressed by the message key, and in a group that key
  # includes who sent it: one command covering several senders cannot be acknowledged.
  it 'marks a group read one participant at a time' do
    group = create(:contact, account: channel.account, identifier: '120363041234567890@g.us', group_type: :group)
    group_inbox = create(:contact_inbox, contact: group, inbox: inbox, source_id: '120363041234567890')
    group_conversation = create(:conversation, contact: group, contact_inbox: group_inbox, inbox: inbox, account: channel.account)
    ana = create(:contact, account: channel.account, phone_number: '+5541999991111')
    bruno = create(:contact, account: channel.account, phone_number: '+5541999992222')
    messages = [
      create(:message, conversation: group_conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, sender: ana, source_id: '3EB0AAAA'),
      create(:message, conversation: group_conversation, inbox: inbox, account: channel.account,
                       message_type: :incoming, sender: bruno, source_id: '3EB0BBBB')
    ]

    channel.read_messages(messages, conversation: group_conversation)

    commands = backend.commands_of('message.mark_read')
    expect(commands.map { |command| command.sender&.id }).to contain_exactly('5541999991111', '5541999992222')
    expect(commands.flat_map(&:message_ids)).to contain_exactly('3EB0AAAA', '3EB0BBBB')
  end

  describe 'the group half' do
    subject(:facade) { channel.provider_service }

    let(:group_jid) { '120363041234567890@g.us' }

    around { |example| with_modified_env(WHATSAPP_GROUPS_ENABLED: 'true') { example.run } }

    it 'reports the group it created with the key the create service reads' do
      group = channel.create_group('Equipe', ['5541999990000@s.whatsapp.net'])

      expect(group[:id]).to end_with('@g.us')
      expect(backend.last_command.participants.map(&:id)).to eq(['5541999990000'])
    end

    it 'refuses a group setting it has no name for' do
      expect { channel.group_setting_update('120363041234567890@g.us', 'teleport', true) }
        .to raise_error(Whatsapp::Session::Errors::InvalidPayload)
    end

    it 'translates a group settings toggle into the contract name' do
      channel.group_member_add_mode('120363041234567890@g.us', 'all_member_add')

      expect(backend.last_command.setting).to eq('member_add_mode')
      expect(backend.last_command.value).to be(true)
    end

    it 'refuses to address a group by anything but a group jid' do
      expect { channel.group_leave('5541999990000@s.whatsapp.net') }
        .to raise_error(Whatsapp::Session::Errors::InvalidPayload)
    end

    # The dashboard hides the group panel when the switch is off, but the endpoints behind
    # it stay routable, so the switch has to hold where the calls land.
    it 'refuses every group operation while the installation has groups off' do
      with_modified_env WHATSAPP_GROUPS_ENABLED: 'false' do
        expect { channel.provider_service.group_leave(group_jid) }
          .to raise_error(Whatsapp::Session::Errors::NotSupported, /groups are disabled/)
        expect { channel.provider_service.create_group('Equipe', []) }
          .to raise_error(Whatsapp::Session::Errors::NotSupported, /groups are disabled/)
      end

      expect(backend.commands).to be_empty
    end

    # The other way the same capability is missing, and it is not the same situation: the
    # switch is on, group threads are in the sidebar and being answered, and only the
    # management surface is absent. An agent told "groups are disabled" here goes looking
    # for a switch that is already on.
    it 'says groups are receivable but unmanageable when only the command surface is missing' do
      allow(Whatsapp::Session::Registry).to receive(:capabilities_for).and_return(%w[groups])

      with_modified_env WHATSAPP_GROUPS_ENABLED: 'true' do
        expect { channel.provider_service.group_leave(group_jid) }
          .to raise_error(Whatsapp::Session::Errors::NotSupported, /cannot manage groups/)
      end

      expect(backend.commands).to be_empty
    end

    # And nothing reaches the provider on the way to that refusal, including the reads the
    # dashboard fires on its own: the panel is gone, and a stale one still mounted must not
    # turn into calls the inbox cannot make.
    it 'reaches the provider for nothing while only the command surface is missing' do
      allow(Whatsapp::Session::Registry).to receive(:capabilities_for).and_return(%w[groups])
      # Named rather than inferred from `backend.commands`: the syncer talks to the
      # provider through its own path, so an empty command list says nothing about whether
      # it ran.
      expect(Whatsapp::Session::Groups::Syncer).not_to receive(:new)

      expect(facade.allow_group_creation?).to be(false)
      facade.sync_group(conversation)

      expect(backend.commands).to be_empty
    end

    # And the guard is on the command surface and not on the switch: an inbox that has both
    # still syncs, or the check above would pass by never syncing at all.
    it 'syncs a group while the command surface is there' do
      expect(Whatsapp::Session::Groups::Syncer).to receive(:new).and_return(instance_double(
                                                                              Whatsapp::Session::Groups::Syncer, perform: nil
                                                                            ))

      facade.sync_group(conversation)
    end

    it 'answers group creation in the shape Groups::CreateService reads' do
      result = facade.create_group('Equipe de Vendas', ['5541999990000@s.whatsapp.net'])

      expect(result).to eq({ id: '120363040000000001@g.us', subject: 'Equipe de Vendas' })
      expect(backend.last_command.subject).to eq('Equipe de Vendas')
    end

    it 'refuses a recipient that is not a group rather than addressing a person' do
      expect { facade.group_leave('5541999990000@s.whatsapp.net') }
        .to raise_error(Whatsapp::Session::Errors::InvalidPayload, /not a group/)
      expect(backend.commands).to be_empty
    end

    it 'translates the dashboard setting names into contract ones' do
      facade.group_setting_update(group_jid, 'restrict', true)

      expect(backend.last_command.setting).to eq('locked')
      expect(backend.last_command.value).to be(true)
    end

    it 'refuses a setting the contract has no name for' do
      expect { facade.group_setting_update(group_jid, 'whatever', true) }
        .to raise_error(Whatsapp::Session::Errors::InvalidPayload, /unknown group setting/)
    end

    # The dashboard endpoint builds the URL from what comes back, so anything but the
    # bare code renders a link with the host in it twice.
    it 'answers an invite with the code alone, and asks for a fresh one when revoking' do
      expect(facade.group_invite_code(group_jid)).to eq('FAKEINVITE0001')
      expect(backend.last_command.revoke).to be(false)

      expect(facade.revoke_group_invite(group_jid)).to eq('FAKEINVITE0001')
      expect(backend.last_command.revoke).to be(true)
    end

    # A provider can do groups without doing join requests: Uazapi is one. Asking its
    # backend anyway raises NotSupported on a routable endpoint.
    it 'answers join requests without the backend when the provider cannot approve them' do
      allow(channel).to receive(:session_capabilities).and_return(%w[groups])

      expect(channel.provider_service.group_join_requests(group_jid)).to eq([])
      expect { channel.provider_service.handle_group_join_requests(group_jid, ['5541999990000@s.whatsapp.net'], 'approve') }
        .to raise_error(Whatsapp::Session::Errors::NotSupported)
      expect(backend.commands).to be_empty
    end

    it 'renders a join request with the keys the dashboard already reads' do
      allow(backend).to receive(:group_join_requests).and_return(
        [{ 'party' => { 'phone' => '5541999990000', 'lid' => '182736451928374' }, 'requested_at' => 1_755_440_000 }]
      )

      expect(facade.group_join_requests(group_jid)).to eq(
        [{ 'jid' => '182736451928374@lid', 'phone_number' => '5541999990000', 'request_time' => 1_755_440_000 }]
      )
    end
  end

  # A linked device that refuses a call ends it on every device of the account, the phone
  # included (`rejected_elsewhere`), so asking the connector to refuse is what stopped the
  # operator's phone from ringing (fazer-ai/chatwoot#850). The offer still reaches the inbox:
  # the connector publishes it whatever the policy says.
  it 'does not ask the connector to refuse calls, on a pairing or on a resume' do
    allow(channel).to receive(:session_capabilities).and_return(%w[calls])

    channel.provider_service.setup_channel_provider
    expect(backend.last_command.calls).to be_nil

    channel.reassert_desired_state
    expect(backend.last_command.calls).to be_nil
  end

  # The channel calls this from before_destroy and from convert_provider!, so it is a
  # teardown: the Baileys service answers it with DELETE /connections/<phone>. Only
  # disconnecting leaves the pairing alive on the provider under a session id Chatwoot
  # has just thrown away.
  it 'deletes the session when the inbox is torn down' do
    channel.begin_session_teardown
    channel.disconnect_channel_provider

    expect(backend.commands_of('session.delete')).to be_present
  end

  # The operator's Disconnect keeps the inbox, and the session id with it. Deleting the
  # session has the connector forget it, epoch counter included, so the pairing after it
  # would start again at epoch 1 under the epoch and position Chatwoot kept for the old one,
  # and every event of it, the QR first, would be dropped (fazer-ai/chatwoot#852). A logout
  # unlinks the device and keeps the counter, which is what pairing again under the same
  # session id needs.
  it 'logs out without deleting the session when the operator disconnects' do
    channel.disconnect_channel_provider

    expect(backend.commands_of('session.logout')).to be_present
    expect(backend.commands_of('session.delete')).to be_empty
  end

  # A backend that cannot tear down its session is not a quiet case. What the fallback can
  # do is end the connection, which leaves the pairing alive under a session id nothing
  # points at any more, and this line is the only trace of that anywhere: the operator sees
  # the inbox disappear and concludes it is over.
  it 'says so in the log when the provider has no teardown' do
    allow(backend).to receive(:delete_session).and_raise(
      Whatsapp::Session::Errors::NotSupported, 'no teardown here'
    )
    allow(Rails.logger).to receive(:warn)

    channel.begin_session_teardown
    channel.disconnect_channel_provider

    expect(Rails.logger).to have_received(:warn).with(/leaves the pairing alive/)
    expect(backend.commands_of('session.disconnect')).to be_present
  end

  # Chatwoot availability is online/offline/busy; the contract knows available and
  # unavailable. The Baileys service maps them, and this used to forward them raw.
  it 'maps account availability onto the two states the contract accepts' do
    channel.update_presence('online')
    expect(backend.last_command.state).to eq('available')

    channel.update_presence('busy')
    expect(backend.last_command.state).to eq('unavailable')
  end

  it 'subscribes to presence with an address, which is what the command carries' do
    facade.presence_subscribe(['182736451928374@lid'])

    expect(backend.last_command.party).to be_a(Whatsapp::Session::Model::Address)
    expect(backend.last_command.party.id).to eq('182736451928374')
  end

  # A close does not un-pair anything: the provider still holds the credentials, so the
  # next connect resumes. Losing the number to a transient disconnect cost a fresh scan.
  it 'resumes after a transient close, and asks for a QR after a logout' do
    channel.update_provider_connection!({ 'connection' => 'open', 'phone_number' => '5541988887777' })
    Whatsapp::Session::ConnectionStateWriter.new(channel).apply(
      Whatsapp::Session::Model::ConnectionState.new(connection: 'close', error: 'connection_closed')
    )
    channel.reload.provider_service.setup_channel_provider
    expect(backend.last_command.pairing).to eq('resume')

    Whatsapp::Session::ConnectionStateWriter.new(channel).apply(
      Whatsapp::Session::Model::ConnectionState.new(connection: 'close', error: 'logged_out')
    )
    channel.reload.provider_service.setup_channel_provider
    expect(backend.last_command.pairing).to eq('qr')
  end

  it 'connects with a QR when the session was never paired, and resumes afterwards' do
    channel.setup_channel_provider
    expect(backend.last_command.pairing).to eq('qr')

    channel.update_provider_connection!({ 'connection' => 'open', 'phone_number' => '5541988887777' })
    channel.provider_service.setup_channel_provider

    expect(backend.last_command.pairing).to eq('resume')
  end

  # The connector takes `proxy: {url}` on every connect, and a connect without it asks for
  # the session to go out directly, so both ways a connect is built have to carry what the
  # inbox names (#743).
  describe 'the proxy the inbox names' do
    let(:proxy_url) { 'socks5://proxy-user:proxy-pass@proxy.example:1080' }

    def name_proxy(url)
      perform_enqueued_jobs { channel.update!(provider_config: channel.provider_config.merge('proxy_url' => url)) }
    end

    it 'is carried by the pairing connect' do
      name_proxy(proxy_url)

      channel.request_pairing_code

      expect(backend.last_command.proxy).to eq('url' => proxy_url)
    end

    it 'is carried by the connect that brings the account back' do
      name_proxy(proxy_url)

      channel.reassert_desired_state

      expect(backend.commands_of('session.connect').last.proxy).to eq('url' => proxy_url)
    end

    it 'is left out when the inbox names none, which asks for a direct connection' do
      channel.request_pairing_code

      expect(backend.last_command.proxy).to be_nil
    end

    it 'refuses a URL the connector would refuse' do
      # A fresh instance: the factory switches the validation off on the one it built.
      saved = Channel::Whatsapp.find(channel.id)
      with_modified_env WHATSAPP_CONNECTOR_ENABLED: 'true' do
        %w[socks5h://proxy.example:1080 ftp://proxy.example:21 socks5:// proxy.example:1080].each do |url|
          saved.provider_config = channel.provider_config.merge('proxy_url' => url)

          expect(saved.valid?).to be(false), "accepted #{url}"
          expect(saved.errors[:provider_config].join).to include('proxy_url')
        end
      end
    end

    it 'accepts the three schemes the connector takes' do
      saved = Channel::Whatsapp.find(channel.id)
      with_modified_env WHATSAPP_CONNECTOR_ENABLED: 'true' do
        %w[http://proxy.example:3128 https://proxy.example:3129 socks5://u:p@proxy.example:1080].each do |url|
          saved.provider_config = channel.provider_config.merge('proxy_url' => url)

          expect(saved.valid?).to be(true), -> { "refused #{url}: #{saved.errors.full_messages.join}" }
        end
      end
    end

    context 'when the inbox is connected' do
      before { channel.update!(provider_connection: { 'connection' => 'open' }) }

      it 'connects again through the new proxy when it changes' do
        expect { name_proxy(proxy_url) }.to change { backend.commands_of('session.connect').size }.by(1)
        expect(backend.commands_of('session.connect').last.proxy).to eq('url' => proxy_url)
      end

      it 'connects again directly when the proxy is cleared' do
        name_proxy(proxy_url)

        expect { name_proxy('') }.to change { backend.commands_of('session.connect').size }.by(1)
        expect(backend.commands_of('session.connect').last.proxy).to be_nil
      end

      it 'does not connect again for a change that is not the proxy' do
        expect do
          channel.update!(provider_config: channel.provider_config.merge('mark_as_read' => false))
        end.not_to(change { backend.commands_of('session.connect').size })
      end
    end

    # The connector resumes a dropped session through the proxy it was last given, and a
    # proxy that stopped working is the likeliest reason to be changing it.
    context 'when the inbox is still paired but its connection dropped' do
      before { channel.update!(provider_connection: { 'connection' => 'close', 'phone_number' => '5511900000743' }) }

      it 'connects again through the new proxy' do
        expect { name_proxy(proxy_url) }.to change { backend.commands_of('session.connect').size }.by(1)
        expect(backend.commands_of('session.connect').last.proxy).to eq('url' => proxy_url)
      end
    end

    # The save has committed by the time the connect goes out, so a connector that cannot be
    # reached must not leave the session on the old proxy for good.
    it 'tries the connect again when the connector could not be reached' do
      channel.update!(provider_connection: { 'connection' => 'open' })
      calls = 0
      allow(backend).to receive(:connect).and_wrap_original do |original, command|
        calls += 1
        raise Whatsapp::Session::Errors::ProviderUnavailable, 'redis down' if calls == 1

        original.call(command)
      end

      expect { name_proxy(proxy_url) }.to change { backend.commands_of('session.connect').size }.by(1)
      expect(backend.commands_of('session.connect').last.proxy).to eq('url' => proxy_url)
    end

    it 'does not send the proxy to a session whose pairing ended before the job ran' do
      channel.update!(provider_connection: { 'connection' => 'open' })
      channel.update!(provider_config: channel.provider_config.merge('proxy_url' => proxy_url))
      channel.update!(provider_connection: { 'connection' => 'close', 'error_code' => 'logged_out' })

      expect { perform_enqueued_jobs }.not_to(change { backend.commands_of('session.connect').size })
    end

    it 'does not interrupt a pairing in progress when its proxy changes' do
      channel.update!(provider_connection: { 'connection' => 'connecting' })

      expect { name_proxy(proxy_url) }.not_to(change { backend.commands_of('session.connect').size })
    end

    it 'does not connect an inbox that was never paired when its proxy changes' do
      expect { name_proxy(proxy_url) }.not_to(change { backend.commands_of('session.connect').size })
    end

    it 'does not connect an inbox whose pairing ended when its proxy changes' do
      channel.update!(provider_connection: { 'connection' => 'close', 'error_code' => 'logged_out' })

      expect { name_proxy(proxy_url) }.not_to(change { backend.commands_of('session.connect').size })
    end
  end

  describe 'history on a backend that pages from a message' do
    let(:model) { Whatsapp::Session::Model }

    before do
      allow(backend.class).to receive_messages(history_on_every_connect?: true, history_needs_anchor?: true)
    end

    def stored(conversation, source_id, at, outgoing: false)
      create(:message, conversation: conversation, inbox: inbox, account: channel.account, source_id: source_id,
                       created_at: at, message_type: outgoing ? :outgoing : :incoming)
    end

    # What arrived while the session was down comes in the same dump as the archive, so a
    # connect that asked for no history would lose it. The setting decides the archive only.
    it 'asks for history on every connect, with the setting off' do
      channel.request_pairing_code
      channel.reassert_desired_state

      expect(backend.commands_of('session.connect').map(&:history_sync)).to eq([true, true])
    end

    it 'still asks for it with the setting on' do
      channel.update!(provider_config: channel.provider_config.merge('history_sync' => true))

      channel.request_pairing_code

      expect(backend.last_command.history_sync).to be(true)
    end

    it 'leaves history off on a backend whose connect follows the setting' do
      allow(backend.class).to receive(:history_on_every_connect?).and_return(false)

      channel.request_pairing_code

      expect(backend.last_command.history_sync).to be(false)
    end

    # The phone only walks back from a message it is shown, and the one to show it is the
    # oldest this inbox holds for the chat, whichever thread it is in: the thread on the
    # screen is usually the newest.
    it 'pages back from the oldest message the contact has in any thread of the inbox' do
      older = create(:conversation, contact: contact, contact_inbox: contact_inbox, inbox: inbox, account: channel.account,
                                    status: :resolved)
      oldest = stored(older, '3EB0OLDEST', 3.days.ago, outgoing: true)
      stored(older, '3EB0MIDDLE', 2.days.ago)
      stored(conversation, '3EB0NEWEST', 1.hour.ago)
      create(:message, conversation: older, inbox: inbox, account: channel.account, source_id: nil, created_at: 4.days.ago,
                       message_type: :activity)

      expect(facade.request_history(contact)).to be(true)

      request = backend.last_command
      expect(request).to be_a(model::Commands::HistoryRequest)
      expect(request.chat.to_h).to eq(model::Address.for_contact(contact).to_h)
      expect(request.before).to have_attributes(id: '3EB0OLDEST', from_me: true)
      expect(request.before.timestamp).to be_within(1000).of((oldest.created_at.to_f * 1000).to_i)
    end

    it 'times the anchor by the clock WhatsApp gave the message, when the row has it' do
      message = stored(conversation, '3EB0TIMED', 1.hour.ago)
      message.update!(content_attributes: { 'external_created_at' => 1_755_430_000 })

      facade.request_history(contact)

      expect(backend.last_command.before.timestamp).to eq(1_755_430_000_000)
    end

    # Anchored on a message that arrived live the phone never answers, so what the import
    # dropped from the dump is asked instead, and a dump message the inbox kept wins over it.
    it 'pages back from where the dropped archive ended when the oldest stored message arrived live' do
      stored(conversation, '3EB0LIVE', 1.hour.ago)
      Whatsapp::Session::HistoryAnchors.remember(
        inbox, model::InboundMessage.new(id: '3EB0DUMPED', chat: model::Address.phone('5541999990000'), from_me: true,
                                         timestamp: 1_755_430_000_000, content: model::Content::Text.new(body: 'x'))
      )

      facade.request_history(contact)

      expect(backend.last_command.before).to have_attributes(id: '3EB0DUMPED', timestamp: 1_755_430_000_000, from_me: true)

      imported = stored(conversation, '3EB0KEPT', 2.days.ago)
      imported.update!(content_attributes: { 'imported' => true })
      facade.request_history(contact)

      expect(backend.last_command.before.id).to eq('3EB0KEPT')
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryAnchors.key(inbox))
    end

    # A live row can be older than the whole dump, and the phone never pages from it: the
    # oldest imported page is where the next request has to start, or every press asks for
    # the same page again.
    it 'pages back from the oldest imported message even with an older live one stored' do
      stored(conversation, '3EB0ANCIENT', 1.year.ago)
      page = stored(conversation, '3EB0PAGE', 1.month.ago)
      page.update!(content_attributes: { 'imported' => true })
      newer_page = stored(conversation, '3EB0NEWERPAGE', 1.week.ago)
      newer_page.update!(content_attributes: { 'imported' => true })

      facade.request_history(contact)

      expect(backend.last_command.before.id).to eq('3EB0PAGE')
    end

    it 'finds the dropped archive under the other spelling of the number' do
      stored(conversation, '3EB0LIVE9', 1.hour.ago)
      Whatsapp::Session::HistoryAnchors.remember(
        inbox, model::InboundMessage.new(id: '3EB0SPELT', chat: model::Address.phone('554199990000'), from_me: false,
                                         timestamp: 1_755_430_000_000, content: model::Content::Text.new(body: 'x'))
      )

      facade.request_history(contact)

      expect(backend.last_command.before.id).to eq('3EB0SPELT')
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryAnchors.key(inbox))
    end

    it 'pages back from the message the caller names' do
      named = stored(conversation, '3EB0NAMED', 1.hour.ago)
      stored(conversation, '3EB0OLDER', 2.days.ago)

      facade.request_history(contact, before: named)

      expect(backend.last_command.before.id).to eq('3EB0NAMED')
    end

    # Without an anchor the connector refuses the request as unsupported, so none is sent.
    it 'asks nothing for a contact with no stored message to page back from' do
      conversation
      create(:message, conversation: conversation, inbox: inbox, account: channel.account, source_id: nil, private: true)

      expect(facade.request_history(contact)).to be(false)
      expect(backend.commands_of('history.request')).to be_empty
    end
  end
end
