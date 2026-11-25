# In-memory backend. It declares every capability and answers every command with a
# plausible canonical result, so the shared examples can pin the Backend contract, and
# handler/outbound specs can run without a provider.
#
# Commands are kept in `commands` for assertions; `emit` builds canonical events with a
# monotonic cursor, the way a real backend would.
# Grows with every command the contract adds, which is the point of it.
class Whatsapp::Session::Backends::Fake < Whatsapp::Session::Backend # rubocop:disable Metrics/ClassLength
  # Per call, never aliased: a constant would hold the pre-reload module. See Handlers::Base.
  def model = Whatsapp::Session::Model

  QR_DATA_URL = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='.freeze
  PAIRING_CODE = 'K7QP-2M4X'.freeze

  class << self
    def provider_key
      'fake'
    end

    def capabilities
      Whatsapp::Session::Capabilities::ALL
    end

    # Everything a backend can do, this one does.
    def unpairs? = true
  end

  attr_reader :commands, :connection_state, :idempotency_keys

  def initialize(channel)
    super
    @commands = []
    @seq = 0
    @connection_state = model::ConnectionState.new(connection: 'close')
  end

  def connect(command)
    record(command)
    @connection_state = model::ConnectionState.new(
      connection: 'connecting',
      qr_data_url: (QR_DATA_URL if command.pairing == 'qr'),
      pairing_code: (PAIRING_CODE if command.pairing == 'code'),
      epoch: (connection_state.epoch || 0) + 1
    )
  end

  def disconnect
    @connection_state = model::ConnectionState.new(connection: 'close', epoch: connection_state.epoch)
    record(model::Commands::SessionDisconnect.new)
  end

  def logout
    @connection_state = model::ConnectionState.new(connection: 'close', epoch: connection_state.epoch)
    record(model::Commands::SessionLogout.new)
  end

  def delete_session
    record(model::Commands::SessionDelete.new)
  end

  def fetch_connection_state
    connection_state
  end

  def import_session(payload)
    record(payload)
    @connection_state = model::ConnectionState.new(connection: 'connecting', epoch: (connection_state.epoch || 0) + 1)
  end

  def fetch_account_limits
    { 'reachout_time_lock' => { 'status' => 'UNLOCKED' }, 'new_chat_cap' => { 'capping_status' => 'ACTIVE' } }
  end

  def send_message(command)
    record(command)
    model::SendResult.new(message_id: command.message_id, timestamp: now_ms, client_ref: command.client_ref)
  end

  def edit_message(command)
    record(command)
    model::SendResult.new(message_id: command.message_id || generated_id, timestamp: now_ms)
  end

  def revoke_message(command)
    record(command)
    true
  end

  def react_message(command)
    record(command)
    model::SendResult.new(message_id: command.message_id || generated_id, timestamp: now_ms)
  end

  def mark_read(command)
    record(command)
    true
  end

  def mark_unread(command)
    record(command)
    true
  end

  def download_media(command)
    record(command)
    model::MediaPayload.new(io: StringIO.new('fake-media'), mime: command.ref&.mime || 'application/octet-stream',
                            filename: 'fake-media', size: 10)
  end

  def request_history(command) = record(command) && nil

  def send_chat_presence(command)
    record(command)
    true
  end

  def update_presence(command)
    record(command)
    true
  end

  def subscribe_presence(command)
    record(command)
    true
  end

  def check_numbers(command, **)
    record(command)
    command.phones.map { |phone| model::NumberCheck.new(phone: phone, exists: true, address: model::Address.phone(phone)) }
  end

  def profile_picture_url(command)
    record(command)
    "https://example.test/avatars/#{command.party.id}.jpg"
  end

  def create_group(command)
    record(command)
    group_info_for(model::Address.group('120363040000000001'), subject: command.subject)
  end

  def group_info(command)
    record(command)
    group_info_for(command.group)
  end

  def list_groups(command)
    record(command)
    [group_info_for(model::Address.group('120363040000000001'))]
  end

  def leave_group(command) = record(command) && true

  def update_group_participants(command)
    record(command)
    command.participants.map { |participant| { 'address' => participant.to_h, 'status' => 'success' } }
  end

  def update_group_name(command)
    record(command)
    true
  end

  def update_group_description(command)
    record(command)
    true
  end

  def update_group_photo(command)
    record(command)
    true
  end

  def update_group_setting(command)
    record(command)
    true
  end

  def group_invite_code(command)
    record(command)
    'FAKEINVITE0001'
  end

  def group_join_requests(command)
    record(command)
    []
  end

  def handle_group_join_requests(command)
    record(command)
    command.participants.map { |participant| { 'address' => participant.to_h, 'status' => 'success' } }
  end

  # The LIDs this fake pairs with a number, as the connector would from what it was shown.
  PAIRED_LIDS = { '182736451928374' => '5541999990000' }.freeze
  def resolve_contact(command, **)
    record(command)
    id = command.party.id
    return model::Party.new(phone: PAIRED_LIDS[id], lid: id) if command.party.kind == 'lid'

    model::Party.new(phone: id, lid: PAIRED_LIDS.key(id))
  end

  # --- test helpers ------------------------------------------------------------------

  # Builds an event as the connector would, with the session id and a monotonic cursor.
  def emit(payload, epoch: connection_state.epoch || 1)
    @seq += 1
    model::Event.build(payload, id: SecureRandom.uuid, sid: channel.id.to_s, epoch: epoch, seq: @seq,
                                ts: now_ms, inst: 'fake')
  end

  def last_command
    commands.last
  end

  def commands_of(type)
    commands.select { |command| command.class.respond_to?(:wire_type) && command.class.wire_type == type }
  end

  private

  def record(command)
    @commands << command
    command
  end

  def generated_id
    "3EB0#{SecureRandom.hex(9).upcase}"
  end

  def now_ms
    (Time.current.to_f * 1000).to_i
  end

  def group_info_for(group, subject: 'Grupo de teste')
    model::GroupInfo.new(
      group: group, subject: subject, size: 1,
      participants: [model::GroupInfo::Participant.new(party: model::Party.new(phone: '5541999990000'), role: 'superadmin')]
    )
  end
end
