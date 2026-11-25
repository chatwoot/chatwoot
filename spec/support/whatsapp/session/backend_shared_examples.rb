# Pins the Backend contract for every session backend: what a backend declares it can do
# must match what it actually implements, in both directions. Include it with the backend
# as `subject` and a `channel`:
#
#   it_behaves_like 'a whatsapp session backend'
RSpec.shared_examples 'a whatsapp session backend' do
  let(:model) { Whatsapp::Session::Model }
  let(:commands) { Whatsapp::Session::Model::Commands }
  let(:phone_address) { model::Address.phone('5541999990000') }
  let(:group_address) { model::Address.group('120363040000000001') }
  let(:text_content) { model::Content::Text.new(body: 'olá') }

  # One representative call per capability-backed method, so the example can prove the
  # method is wired without knowing anything about the backend.
  let(:sample_calls) do
    {
      import_session: [{ 'session' => { 'creds' => 'redacted' } }],
      edit_message: [commands::MessageEdit.new(target_id: '3EB0AAAA', to: phone_address, content: text_content)],
      revoke_message: [commands::MessageRevoke.new(target_id: '3EB0AAAA', to: phone_address)],
      react_message: [commands::MessageReact.new(to: phone_address, target_id: '3EB0AAAA', emoji: '👍')],
      send_chat_presence: [commands::ChatPresence.new(chat: phone_address, state: 'composing')],
      update_presence: [commands::PresenceSet.new(state: 'available')],
      subscribe_presence: [commands::PresenceSubscribe.new(party: phone_address)],
      mark_read: [commands::MessageMarkRead.new(chat: phone_address, message_ids: ['3EB0AAAA'])],
      mark_unread: [commands::MessageMarkUnread.new(chat: phone_address)],
      check_numbers: [commands::ContactCheck.new(phones: ['5541999990000'])],
      profile_picture_url: [commands::ContactProfilePicture.new(party: phone_address)],
      fetch_account_limits: [],
      download_media: [
        commands::MessageDownloadMedia.new(chat: phone_address, message_id: '3EB0AAAA',
                                           ref: model::MediaRef.new(kind: 'url', url: 'https://example.test/file.jpg'))
      ],
      group_info: [commands::GroupInfo.new(group: group_address)],
      update_group_participants: [
        commands::GroupParticipantsUpdate.new(group: group_address, participants: [phone_address], action: 'add')
      ],
      group_invite_code: [commands::GroupInviteGet.new(group: group_address)],
      group_join_requests: [commands::GroupJoinRequestsList.new(group: group_address)]
    }
  end

  def not_supported?(method, args)
    subject.public_send(method, *args)
    false
  rescue Whatsapp::Session::Errors::NotSupported
    true
  rescue StandardError
    # Anything else is the backend's own business: the contract only cares that the
    # method exists and is not stubbed out as unsupported.
    false
  end

  describe 'the declared contract' do
    it 'declares a provider key' do
      expect(described_class.provider_key).to be_present
    end

    it 'declares only known capabilities' do
      expect(described_class.capabilities - Whatsapp::Session::Capabilities::ALL).to be_empty
    end

    it 'validates a config without touching the network' do
      expect(described_class.validate_config({})).to be_an(Array)
    end
  end

  describe 'capabilities vs implementation' do
    it 'implements every method its declared capabilities cover' do
      missing = Whatsapp::Session::Capabilities::METHODS.filter_map do |capability, method|
        next unless described_class.supports?(capability)
        next unless sample_calls.key?(method)

        method if not_supported?(method, sample_calls[method])
      end

      expect(missing).to be_empty, "declared but not implemented: #{missing.join(', ')}"
    end

    it 'refuses every method its capabilities do not cover' do
      leaking = Whatsapp::Session::Capabilities::METHODS.filter_map do |capability, method|
        next if described_class.supports?(capability)
        next unless sample_calls.key?(method)

        method unless not_supported?(method, sample_calls[method])
      end

      expect(leaking).to be_empty, "not declared but answered anyway: #{leaking.join(', ')}"
    end
  end

  describe 'the session lifecycle' do
    it 'returns a connection state when connecting' do
      state = subject.connect(commands::SessionConnect.new(pairing: 'qr'))

      expect(state).to be_a(model::ConnectionState)
      expect(state.connection).to be_in(model::ConnectionState::CONNECTIONS)
    end

    # The pairing modes are the one pair of capabilities `Capabilities::METHODS` cannot
    # cover, because both are the same method told which mode to use. Declaring
    # `code_pairing` and then refusing the mode is the failure that map exists to catch
    # everywhere else, so it is caught here instead.
    it 'pairs in every mode it declares' do
      modes = { 'qr_pairing' => 'qr', 'code_pairing' => 'code' }.select { |capability, _| described_class.supports?(capability) }
      states = modes.transform_values do |mode|
        subject.connect(commands::SessionConnect.new(pairing: mode, phone: '5541999991111'))
      rescue Whatsapp::Session::Errors::NotSupported
        nil
      end

      expect(states.compact_blank.keys).to eq(modes.keys)
    end

    it 'reports the connection state' do
      expect(subject.fetch_connection_state).to be_a(model::ConnectionState)
    end
  end

  describe 'sending' do
    let(:send_command) do
      commands::MessageSend.new(message_id: '3EB0BBBBCCCCDDDDEEEE', to: phone_address, content: text_content)
    end

    it 'returns the provider id of the sent message' do
      result = subject.send_message(send_command)

      expect(result).to be_a(model::SendResult)
      expect(result.message_id).to be_present
    end

    it 'echoes back the reserved id when it accepts a caller-supplied one' do
      skip 'backend assigns its own ids' unless described_class.supports?('echo_by_reserved_id')

      expect(subject.send_message(send_command).message_id).to eq('3EB0BBBBCCCCDDDDEEEE')
    end
  end
end
