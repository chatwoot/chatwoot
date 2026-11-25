# Canonical outbound command payloads, one class per wire type. The connector backend
# publishes them to Redis; the Uazapi backend translates them into HTTP calls. Both are
# built by the same callers.
module Whatsapp::Session::Model::Commands
  Address = Whatsapp::Session::Model::Address
  Content = Whatsapp::Session::Model::Content
  MediaRef = Whatsapp::Session::Model::MediaRef
  Serializable = Whatsapp::Session::Model::Serializable

  class SessionConnect < Data.define(:pairing, :phone, :device_name, :proxy, :groups, :history_sync, :calls)
    include Serializable
    wire_type 'session.connect'

    PAIRING_MODES = %w[qr code resume].freeze
    defaults groups: false, history_sync: false

    def initialize(**attributes)
      pairing = attributes[:pairing].to_s
      raise Whatsapp::Session::Errors::InvalidPayload, "unknown pairing mode: #{pairing}" unless PAIRING_MODES.include?(pairing)

      super(**attributes, pairing: pairing)
    end
  end

  class SessionDisconnect < Data.define
    include Serializable
    wire_type 'session.disconnect'
  end

  class SessionLogout < Data.define
    include Serializable
    wire_type 'session.logout'
  end

  class SessionDelete < Data.define
    include Serializable
    wire_type 'session.delete'
  end

  class SessionStatus < Data.define
    include Serializable
    wire_type 'session.status'
  end

  class SessionUpdate < Data.define(:config)
    include Serializable
    wire_type 'session.update'
  end

  class SessionWake < Data.define(:desired)
    include Serializable
    wire_type 'session.wake'
  end

  class AdminPing < Data.define
    include Serializable
    wire_type 'admin.ping'
  end

  class PairingRequestCode < Data.define(:phone)
    include Serializable
    wire_type 'pairing.request_code'
  end

  class PairingPasskeyResponse < Data.define(:request_id, :credential)
    include Serializable
    wire_type 'pairing.passkey_response'
  end

  class PairingPasskeyConfirm < Data.define(:request_id, :confirmed)
    include Serializable
    wire_type 'pairing.passkey_confirm'
  end

  class Quoted < Data.define(:id, :participant, :from_me)
    include Serializable
    coerce participant: Address
    defaults from_me: false
  end

  class MessageSend < Data.define(:message_id, :to, :content, :quoted, :mentions, :ephemeral, :client_ref)
    include Serializable
    wire_type 'message.send'
    coerce to: Address, content: Content, quoted: Quoted, mentions: [Address]
  end

  class MessageEdit < Data.define(:message_id, :target_id, :to, :content)
    include Serializable
    wire_type 'message.edit'
    coerce to: Address, content: Content
  end

  class MessageRevoke < Data.define(:target_id, :to, :participant)
    include Serializable
    wire_type 'message.revoke'
    coerce to: Address, participant: Address
  end

  class MessageReact < Data.define(:message_id, :to, :target_id, :target_from_me, :target_participant, :emoji)
    include Serializable
    wire_type 'message.react'
    coerce to: Address, target_participant: Address
    defaults target_from_me: false
  end

  class MessageMarkRead < Data.define(:chat, :message_ids, :sender, :type)
    include Serializable
    wire_type 'message.mark_read'
    coerce chat: Address, sender: Address
    defaults type: 'read'
  end

  class MessageMarkUnread < Data.define(:chat, :last_message_id, :from_me)
    include Serializable
    wire_type 'message.mark_unread'
    coerce chat: Address
    defaults from_me: false
  end

  class MessageDownloadMedia < Data.define(:chat, :message_id, :ref)
    include Serializable
    wire_type 'message.download_media'
    coerce chat: Address, ref: MediaRef
  end

  # Where a backwards page starts. An id on its own cannot address one: whatsmeow takes a
  # whole `types.MessageInfo` to build the request, so the anchor carries the timestamp and
  # the direction alongside it. Chatwoot holds all three on the message row, so nothing has
  # to be reconstructed at the far end.
  class HistoryAnchor < Data.define(:id, :timestamp, :from_me)
    include Serializable
    defaults from_me: false

    # The anchor a stored message stands for, timed by WhatsApp's own clock when the row has
    # it: that is the number the phone indexed the message by, while `created_at` on a live
    # row is when it was filed here.
    def self.for_message(message)
      return if message.blank?

      sent = message.content_attributes&.dig('external_created_at').presence
      timestamp = sent ? sent.to_i * 1000 : (message.created_at.to_f * 1000).to_i
      new(id: message.source_id, timestamp: timestamp, from_me: message.outgoing?)
    end
  end

  # The history a chat already has on the phone. `count` is a hint rather than a cap: a
  # live instance answered a request for 50 with 947 messages, so what bounds the import
  # is the policy on the way in, not this. `before` is the anchor to page backwards from,
  # which is what makes a second request continue the first instead of repeating it.
  class HistoryRequest < Data.define(:chat, :count, :before)
    include Serializable
    wire_type 'history.request'
    coerce chat: Address, before: HistoryAnchor
  end

  class PresenceSet < Data.define(:state)
    include Serializable
    wire_type 'presence.set'
  end

  class PresenceSubscribe < Data.define(:party)
    include Serializable
    wire_type 'presence.subscribe'
    coerce party: Address
  end

  class ChatPresence < Data.define(:chat, :state)
    include Serializable
    wire_type 'chat.presence'
    coerce chat: Address
  end

  class ContactCheck < Data.define(:phones)
    include Serializable
    wire_type 'contact.check'
  end

  class ContactProfilePicture < Data.define(:party, :preview)
    include Serializable
    wire_type 'contact.profile_picture'
    coerce party: Address
    defaults preview: true
  end

  class ContactInfo < Data.define(:party)
    include Serializable
    wire_type 'contact.info'
    coerce party: Address
  end

  class ContactResolve < Data.define(:party)
    include Serializable
    wire_type 'contact.resolve'
    coerce party: Address
  end

  class GroupCreate < Data.define(:subject, :participants)
    include Serializable
    wire_type 'group.create'
    coerce participants: [Address]
  end

  class GroupInfo < Data.define(:group)
    include Serializable
    wire_type 'group.info'
    coerce group: Address
  end

  class GroupList < Data.define
    include Serializable
    wire_type 'group.list'
  end

  class GroupLeave < Data.define(:group)
    include Serializable
    wire_type 'group.leave'
    coerce group: Address
  end

  class GroupParticipantsUpdate < Data.define(:group, :participants, :action)
    include Serializable
    wire_type 'group.participants.update'
    coerce group: Address, participants: [Address]

    ACTIONS = %w[add remove promote demote].freeze
  end

  class GroupNameSet < Data.define(:group, :subject)
    include Serializable
    wire_type 'group.name.set'
    coerce group: Address
  end

  class GroupDescriptionSet < Data.define(:group, :description)
    include Serializable
    wire_type 'group.description.set'
    coerce group: Address
  end

  class GroupPhotoSet < Data.define(:group, :image)
    include Serializable
    wire_type 'group.photo.set'
    coerce group: Address
  end

  class GroupSettingsSet < Data.define(:group, :setting, :value)
    include Serializable
    wire_type 'group.settings.set'
    coerce group: Address

    SETTINGS = %w[announce locked join_approval member_add_mode].freeze
  end

  class GroupInviteGet < Data.define(:group, :revoke)
    include Serializable
    wire_type 'group.invite.get'
    coerce group: Address
    defaults revoke: false
  end

  class GroupJoinRequestsList < Data.define(:group)
    include Serializable
    wire_type 'group.join_requests.list'
    coerce group: Address
  end

  class GroupJoinRequestsUpdate < Data.define(:group, :participants, :action)
    include Serializable
    wire_type 'group.join_requests.update'
    coerce group: Address, participants: [Address]

    ACTIONS = %w[approve reject].freeze
  end

  class CallReject < Data.define(:call_id, :from)
    include Serializable
    wire_type 'call.reject'
    coerce from: Address
  end

  # The browser's WebRTC answer to a call the connector offered with an `sdp`, or the media
  # `stream` ({'url' => 'wss://...'}) a voice agent takes the call over instead.
  class CallAccept < Data.define(:call_id, :sdp, :stream)
    include Serializable
    wire_type 'call.accept'
  end

  # Rings `to` with the browser's WebRTC offer. An RPC: the result is the call id that
  # `call.answered` and `call.terminate` carry for it.
  class CallStart < Data.define(:to, :sdp)
    include Serializable
    wire_type 'call.start'
    coerce to: Address
  end

  class CallTerminate < Data.define(:call_id)
    include Serializable
    wire_type 'call.terminate'
  end

  CLASSES = [
    SessionConnect, SessionDisconnect, SessionLogout, SessionDelete, SessionStatus, SessionUpdate, SessionWake,
    AdminPing, PairingRequestCode, PairingPasskeyResponse, PairingPasskeyConfirm, HistoryRequest, MessageSend, MessageEdit,
    MessageRevoke, MessageReact, MessageMarkRead, MessageMarkUnread, MessageDownloadMedia, PresenceSet,
    PresenceSubscribe, ChatPresence, ContactCheck, ContactProfilePicture, ContactInfo, ContactResolve, GroupCreate,
    GroupInfo, GroupList, GroupLeave, GroupParticipantsUpdate, GroupNameSet, GroupDescriptionSet, GroupPhotoSet,
    GroupSettingsSet, GroupInviteGet, GroupJoinRequestsList, GroupJoinRequestsUpdate, CallReject,
    CallAccept, CallStart, CallTerminate
  ].freeze

  BY_TYPE = CLASSES.index_by(&:wire_type).freeze
  TYPES = BY_TYPE.keys.freeze

  # Commands whose caller waits for a result. Everything else is fire-and-forget: the
  # outcome, when there is one, comes back as an event.
  RPC_TYPES = %w[
    session.connect session.status session.update admin.ping
    message.send message.edit message.revoke message.react message.download_media
    history.request
    contact.check contact.profile_picture contact.info contact.resolve
    group.create group.info group.list group.leave group.participants.update group.name.set
    group.description.set group.photo.set group.settings.set group.invite.get
    group.join_requests.list group.join_requests.update
    call.start
  ].freeze

  def self.rpc?(type)
    RPC_TYPES.include?(type)
  end

  def self.build(type, payload)
    klass = BY_TYPE[type]
    raise Whatsapp::Session::Errors::InvalidPayload, "unknown command type: #{type.inspect}" if klass.nil?

    klass.from_h(payload || {})
  end
end
