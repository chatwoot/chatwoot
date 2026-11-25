require 'rails_helper'

# Every example here runs against a body captured from a live instance on 19/08/2026,
# redacted and committed under spec/fixtures/whatsapp/session/uazapi/webhook. The
# provider documents none of these shapes, so a golden body is the only thing that keeps
# the translator honest about what actually arrives.
RSpec.describe Whatsapp::Session::Backends::Uazapi::WebhookTranslator do
  subject(:events) { described_class.new(channel, body).perform }

  # Pointed at the instance the captures came from, since the translator refuses a body
  # that names a different one.
  let(:channel) do
    create(:channel_whatsapp, provider: 'uazapi', validate_provider_config: false, sync_templates: false,
                              provider_config: { 'base_url' => 'https://free.uazapi.com', 'token' => 'instance-token' })
  end
  let(:model) { Whatsapp::Session::Model }

  # One loader for two dozen examples, which is the repetition a helper is for.
  def fixture(name)
    JSON.parse(Rails.root.join("spec/fixtures/whatsapp/session/uazapi/webhook/#{name}.json").read)
  end

  describe 'the connection' do
    context 'when the instance is asking for a QR' do
      let(:body) { fixture('connection_connecting_qr') }

      it 'carries the code the operator has to scan' do
        expect(events.map(&:type)).to eq(['pairing.qr'])
        expect(events.first.payload.png_data_url).to start_with('data:image/png;base64,')
      end
    end

    context 'when the session opened' do
      let(:body) { fixture('connection_connected') }

      it 'reports the number it paired with' do
        expect(events.first.type).to eq('session.state')
        expect(events.first.payload).to have_attributes(state: 'open', phone: '5511999990001')
      end
    end

    # `owner` keeps the previous number while the instance sits disconnected, and a state
    # naming a number this inbox is not configured for is what quarantines it.
    context 'when the instance is disconnected' do
      let(:body) { fixture('connection_connected').merge('instance' => { 'status' => 'disconnected' }) }

      it 'reports no number at all' do
        expect(events.first.payload).to have_attributes(state: 'close', phone: nil)
      end
    end
  end

  describe 'an incoming message' do
    let(:body) { fixture('message_incoming_text') }
    let(:message) { events.first.payload.message }

    it 'is addressed by the chat and carries both of the sender identities' do
      expect(events.first.type).to eq('message.received')
      expect(message.id).to eq('3EB00000000000000001')
      expect(message.chat).to eq(model::Address.phone('553499990002'))
      expect(message.sender).to have_attributes(lid: '900000100000000', phone: '553499990002', push_name: 'Ana Souza')
      expect(message).to have_attributes(from_me: false, timestamp: 1_787_161_667_000)
      expect(message.content).to have_attributes(wire_type: 'text', body: 'oi tudo bom')
    end
  end

  describe 'an echo of what the connected phone sent' do
    let(:body) { fixture('message_echo_text_to_peer') }
    let(:message) { events.first.payload.message }

    # The chat is the peer and the sender is us, which is what tells the handler where the
    # conversation goes: it reads the chat, not the sender, for an outgoing message.
    it 'is addressed to the peer and carries the id Chatwoot reserved' do
      expect(message).to have_attributes(from_me: true, client_ref: 'cw:capture-005')
      expect(message.chat).to eq(model::Address.phone('553499990002'))
      expect(message.sender.phone).to eq('5511999990001')
    end
  end

  describe 'media' do
    context 'with an image' do
      let(:body) { fixture('message_incoming_image') }
      let(:content) { events.first.payload.message.content }

      # The URL in the body is the encrypted blob on WhatsApp's CDN, so the reference has
      # to be the message: only the provider can decrypt it.
      it 'points at the message rather than at the CDN url' do
        expect(content).to have_attributes(wire_type: 'media', kind: 'image', mime: 'image/jpeg',
                                           caption: 'foto aleatória com legenda', voice_note: false, size: 122_885)
        expect(content.ref).to have_attributes(kind: 'uazapi_message', id: '3EB00000000000000979', url: nil)
      end
    end

    context 'with a voice note' do
      let(:body) { fixture('message_incoming_voice_note') }
      let(:content) { events.first.payload.message.content }

      it 'is marked as one' do
        expect(content).to have_attributes(kind: 'audio', voice_note: true, duration: 5)
      end
    end

    context 'with a sticker' do
      let(:body) { fixture('message_echo_sticker') }

      it 'keeps the sticker kind rather than filing it as an image' do
        expect(events.first.payload.message.content.kind).to eq('sticker')
      end
    end

    context 'with a document' do
      let(:body) { fixture('message_echo_document') }

      it 'carries the file name' do
        expect(events.first.payload.message.content).to have_attributes(kind: 'document', filename: 'contrato.pdf')
      end
    end
  end

  # `type` is "text" on this one: only `messageType` tells a location apart.
  describe 'a location' do
    let(:body) { fixture('message_echo_location') }

    it 'is read off messageType, not off type' do
      expect(events.first.payload.message.content).to have_attributes(
        wire_type: 'location', latitude: -25.4284, longitude: -49.2733, name: 'Curitiba', address: 'PR, Brasil'
      )
    end
  end

  describe 'a shared contact' do
    let(:body) { fixture('message_echo_contact') }

    it 'carries the card the writer stores' do
      card = events.first.payload.message.content.contacts.first

      expect(card['display_name']).to eq('Contato Teste')
      expect(card['vcard']).to include('BEGIN:VCARD')
    end
  end

  describe 'a reaction' do
    let(:body) { fixture('reaction_incoming') }

    it 'becomes an event of its own, pointing at the message it annotates' do
      expect(events.first.type).to eq('message.reaction')
      expect(events.first.payload).to have_attributes(
        id: '3EB00000000000000981', target_id: '3EB00000000000000979', emoji: '👍', from_me: false
      )
    end
  end

  # An edit is an ordinary message with an id of its own; `edited` names the one it
  # replaces, and that is what the event has to be addressed to.
  describe 'an edit' do
    let(:body) { fixture('message_edited_echo') }

    it 'is addressed to the original message' do
      expect(events.first.type).to eq('message.edited')
      expect(events.first.payload).to have_attributes(message_id: '3EB00000000000000003', from_me: true)
      expect(events.first.payload.content.body).to eq('captura 2 editada')
    end
  end

  describe 'a receipt' do
    context 'when a message was delivered' do
      let(:body) { fixture('update_delivered') }

      it 'reports the ids in one event' do
        expect(events.first.type).to eq('message.receipt')
        expect(events.first.payload).to have_attributes(type: 'delivered', message_ids: ['3EB00000000000000011'])
        expect(events.first.payload.timestamp).to eq(1_787_161_784_000)
      end
    end

    # Opening a chat produced a single event naming 246 messages, most of them from before
    # this inbox existed. That is why a receipt whose ids are all unknown is not treated as
    # an event that arrived too early.
    context 'when a whole chat was read at once' do
      let(:body) { fixture('update_read_bulk') }

      it 'keeps the batch together' do
        expect(events.first.payload.type).to eq('read')
        expect(events.first.payload.message_ids.size).to eq(246)
      end
    end

    # `event.Type` was `Read` from a peer and `read` from our own mark-read call, while
    # the top-level `state` was `Read` in both.
    context 'when the provider lowercases the event type' do
      let(:body) { fixture('update_read_lowercase_type') }

      it 'is still read as a read receipt, and its ISO timestamp as milliseconds' do
        expect(events.first.payload.type).to eq('read')
        expect(events.first.payload.timestamp).to eq(Time.zone.parse('2026-08-19T17:51:41Z').to_i * 1000)
      end
    end

    context 'when a voice note was played' do
      let(:body) { fixture('update_played') }

      it 'reports every id it names' do
        expect(events.first.payload).to have_attributes(type: 'played')
        expect(events.first.payload.message_ids.size).to eq(4)
      end
    end

    # The provider's own bookkeeping: it downloaded the file to its disk, which says
    # nothing about the message.
    context 'when the provider downloaded a file' do
      let(:body) { fixture('update_file_downloaded') }

      it 'produces nothing' do
        expect(events).to be_empty
      end
    end
  end

  describe 'a deletion' do
    let(:body) { fixture('update_deleted') }

    it 'becomes a revoke by the contact' do
      expect(events.first.type).to eq('message.revoked')
      expect(events.first.payload).to have_attributes(message_id: '3EB00000000000000001', by: 'contact')
    end

    context 'when the connected phone is the one that deleted it' do
      let(:body) { fixture('update_deleted').tap { |raw| raw['event']['IsFromMe'] = true } }

      it 'is a revoke by us' do
        expect(events.first.payload.by).to eq('self')
      end
    end

    # A bulk deletion names every message in one event, and the revoke handler is a no-op
    # on a message already flagged, so replaying the body is safe.
    context 'when several messages were deleted at once' do
      let(:body) { fixture('update_deleted').tap { |raw| raw['event']['MessageIDs'] = %w[3EB0AAAA 3EB0BBBB] } }

      it 'produces one revoke each' do
        expect(events.map(&:type)).to eq(%w[message.revoked message.revoked])
        expect(events.map { |event| event.payload.message_id }).to eq(%w[3EB0AAAA 3EB0BBBB])
      end
    end
  end

  describe 'presence' do
    # Every presence event in the capture was our own: `/message/presence` comes back on
    # the webhook naming the peer's chat, and dispatching it would show the contact typing
    # every time an agent does.
    context 'when it is the echo of our own typing' do
      let(:body) { fixture('presence_from_me') }

      it 'produces nothing' do
        expect(events).to be_empty
      end
    end

    context 'when the contact is typing' do
      let(:body) do
        fixture('presence_from_me').tap { |raw| raw['event'].merge!('IsFromMe' => false, 'State' => 'composing') }
      end

      it 'becomes a typing indicator' do
        expect(events.first.type).to eq('chat.presence')
        expect(events.first.payload.state).to eq('composing')
      end
    end

    context 'when the contact is recording' do
      let(:body) do
        fixture('presence_from_me').tap do |raw|
          raw['event'].merge!('IsFromMe' => false, 'State' => 'composing', 'Media' => 'audio')
        end
      end

      it 'is told apart from typing by the media hint' do
        expect(events.first.payload.state).to eq('recording')
      end
    end
  end

  describe 'groups' do
    context 'when a group was created' do
      let(:body) { fixture('group_created') }

      it 'carries the whole roster' do
        expect(events.first.type).to eq('group.joined')
        info = events.first.payload.info
        expect(info.subject).to eq('captura chatwoot')
        expect(info.participants.size).to eq(2)
        expect(info.admins.map { |member| member.party.lid }).to contain_exactly('90000020000000')
      end
    end

    # A membership change carries no `Type` at all: which array is populated is the whole
    # signal, and the same people are named twice, once by number and once by LID.
    context 'when a participant left' do
      let(:body) { fixture('group_participant_left') }

      it 'pairs the two identities of whoever left' do
        expect(events.first.type).to eq('group.updated')
        changes = events.first.payload.changes
        expect(changes.leave.map { |party| [party.lid, party.phone] }).to eq([%w[900000100000000 553499990002]])
        expect(changes.join).to be_nil
        expect(events.first.payload.actor.phone).to eq('5511999990001')
      end
    end

    # whatsmeow reports a changed field either bare or wrapped in the struct that carries
    # its metadata, and `nil` has to keep meaning "not changed".
    context 'when the group was renamed' do
      let(:body) do
        fixture('group_participant_left').tap { |raw| raw['event'].merge!('Name' => { 'Name' => 'novo nome' }, 'Leave' => nil) }
      end

      it 'reads the value out of the wrapper' do
        expect(events.first.payload.changes.subject).to eq('novo nome')
      end
    end

    # Measured against real accounts on 10/09/2026: turning approval on and turning it off
    # both arrive as `MembershipApprovalMode: {IsJoinApprovalRequired: true}`, because
    # WhatsApp sends the same tag in both directions with the state in a child element and
    # whatsmeow reads only the tag. So the value is a coin flip, and describing it would put
    # "join approval enabled" in the thread at the moment somebody disabled it.
    context 'when the approval setting was moved' do
      let(:body) do
        fixture('group_participant_left').tap do |raw|
          raw['event'].merge!('Leave' => nil, 'LeaveLid' => nil,
                              'MembershipApprovalMode' => { 'IsJoinApprovalRequired' => true })
        end
      end

      it 'pings the group instead of asserting which way it went' do
        expect(events.first.type).to eq('group.activity')
        expect(events.first.payload.groups.first.id).to be_present
      end

      it 'describes nothing about the setting itself' do
        expect(events.map(&:type)).not_to include('group.updated')
      end
    end

    # A change the contract can carry is still described, and the setting simply does not
    # appear: the handler reads an absent field as "not reported", which is true.
    context 'when the approval setting moved alongside something describable' do
      let(:body) do
        fixture('group_participant_left').tap do |raw|
          raw['event'].merge!('Leave' => nil, 'LeaveLid' => nil, 'Name' => { 'Name' => 'novo nome' },
                              'MembershipApprovalMode' => { 'IsJoinApprovalRequired' => true })
        end
      end

      it 'describes what it can and stays quiet about the rest' do
        changes = events.first.payload.changes

        expect(events.first.type).to eq('group.updated')
        expect(changes.subject).to eq('novo nome')
        expect(changes.to_h).not_to have_key(:join_approval)
      end
    end

    context 'when nothing actually changed' do
      let(:body) do
        fixture('group_participant_left').tap { |raw| raw['event'].merge!('Leave' => nil, 'LeaveLid' => nil) }
      end

      it 'produces nothing' do
        expect(events).to be_empty
      end
    end
  end

  describe 'what it refuses to guess at' do
    context 'with an event type this build does not subscribe to' do
      let(:body) { fixture('chats_ignored') }

      it 'produces nothing' do
        expect(events).to be_empty
      end
    end

    context 'with a message type it cannot render' do
      let(:body) { fixture('message_incoming_text').tap { |raw| raw['message']['messageType'] = 'PollCreationMessage' } }

      it 'stores it as unsupported rather than dropping the message' do
        expect(events.first.payload.message.content).to have_attributes(wire_type: 'unsupported', reason: 'unknown_type')
      end
    end

    context 'with an empty body' do
      let(:body) { {} }

      it 'produces nothing' do
        expect(events).to be_empty
      end
    end
  end

  # Every body in the capture, so a change here cannot quietly stop reading one of the
  # shapes this provider actually sends, and so the property the dispatching job depends
  # on stays true: a body carries at most one event, except a bulk revoke, whose handler
  # is a no-op the second time.
  describe 'the whole capture' do
    let(:bodies) do
      Dir[Rails.root.join('spec/fixtures/whatsapp/session/uazapi/webhook/*.json')].to_h do |path|
        [File.basename(path, '.json'), JSON.parse(File.read(path))]
      end
    end

    it 'reads every recorded body into events this build knows' do
      translated = bodies.transform_values { |raw| described_class.new(channel, raw).perform }

      expect(translated.values.flatten).to all(be_known)
      expect(translated.reject { |_name, list| list.size <= 1 }).to be_empty
    end
  end

  # The instance token is in every body. Nothing may copy it into an event, because an
  # event becomes a job argument, a log line and, through `raw`, a database column.
  it 'never carries the instance credential into an event' do
    bodies = Dir[Rails.root.join('spec/fixtures/whatsapp/session/uazapi/webhook/*.json')].map { |path| JSON.parse(File.read(path)) }
    serialized = bodies.flat_map { |raw| described_class.new(channel, raw.merge('token' => 'secret-token')).perform }
                       .map { |event| event.to_frame.to_json }

    expect(serialized).to all(satisfy { |frame| frame.exclude?('secret-token') })
  end

  # A body is authenticated when it arrives and dispatched later. An inbox re-pointed at
  # another instance in between would file the old one's messages under the new: the token
  # that authenticated them is gone by then, and nothing else in a queued job says which
  # instance it was meant for.
  it 'refuses a body that names an instance this inbox is no longer pointed at' do
    # Moving the inbox lets go of the instance it leaves, which is a request of its own.
    stub_request(:post, "#{channel.provider_config['base_url']}/webhook").to_return(status: 200, body: '{}')
    channel.update!(provider_config: channel.provider_config.merge('base_url' => 'https://other.uazapi.com'))

    events = described_class.new(channel.reload, fixture('message_incoming_text')).perform

    expect(events).to be_empty
  end
end
