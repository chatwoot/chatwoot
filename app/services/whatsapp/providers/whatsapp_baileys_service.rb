class Whatsapp::Providers::WhatsappBaileysService < Whatsapp::Providers::BaseService # rubocop:disable Metrics/ClassLength
  include BaileysHelper
  include Whatsapp::BaileysRequestOptions
  include Whatsapp::TransportFailure
  include Whatsapp::CredentialCheck

  # Legacy errors inherit from the session hierarchy so every caller rescues a single
  # namespace, whatever the provider. Nothing else about this service changes: it is
  # frozen until baileys is removed.
  class ProviderUnavailableError < Whatsapp::Session::Errors::ProviderUnavailable; end
  class GroupParticipantNotAllowedError < Whatsapp::Session::Errors::GroupParticipantNotAllowed; end
  class MessageAlreadyProcessingError < Whatsapp::Session::Errors::MessageAlreadyProcessing; end
  # The send reached its deadline. Retryable: the same send may well work next time.
  class SendTimeoutError < Whatsapp::Session::Errors::Timeout; end

  # A previous send timed out and may or may not have reached WhatsApp. NOT retryable:
  # resending could deliver the message twice, and only the operator can tell. Reached
  # only when the send did not reserve a message id, since with one a resend reuses the
  # same WhatsApp key.id and WhatsApp itself dedupes it.
  class SendOutcomeUnknownError < Whatsapp::Session::Errors::SendOutcomeUnknown; end

  # The API knows this connection is not accepting sends at all (its send-stall circuit
  # breaker is open) and refused without touching the socket. Retryable: the provider
  # recreates the socket on its own, and the next attempt after that succeeds.
  class SendStalledError < Whatsapp::Session::Errors::ProviderUnavailable
    CODE = 'send_stalled'.freeze
  end

  DEFAULT_CLIENT_NAME = ENV.fetch('BAILEYS_PROVIDER_DEFAULT_CLIENT_NAME', nil)
  DEFAULT_URL = ENV.fetch('BAILEYS_PROVIDER_DEFAULT_URL', nil)
  DEFAULT_API_KEY = ENV.fetch('BAILEYS_PROVIDER_DEFAULT_API_KEY', nil)
  # Consecutive failed reconnect cycles (provider quarantine strikes, see
  # baileys-api) after which a reconnect attempt discards the stored session
  # first. 3 full cycles span several minutes of backoff — a rejected
  # session, not a transient blip.
  RECONNECT_LOOP_RESET_STRIKES = 3
  # How far back one history request asks. The phone treats it as a hint and routinely
  # answers with far more (947 messages for a request of 50, measured), so the ceiling that
  # matters is the one the import applies on the way in; this is the API's own cap.
  HISTORY_REQUEST_COUNT = 50
  # Shown to the agent on a message whose send outcome cannot be determined. Says what
  # to do, because "unknown" alone leaves them with no next step.
  # Persisted as external_error and rendered to the agent, so it is translated like every
  # other agent-facing string. Resolved at raise time rather than at load: I18n.locale is
  # per-request, and a constant would freeze whichever locale booted the process.
  OUTGOING_ERRORS_SCOPE = 'errors.inboxes.channel.outgoing'.freeze

  # One switch for the whole WhatsApp group subsystem, resolved in one place. Reading the
  # legacy variable here while the registry reads the new one would let an inbox advertise
  # `groups` in its capabilities and still refuse to create one.
  def self.groups_enabled?
    Whatsapp::Session::Registry.groups_enabled?
  end

  # How long the provider picker waits on the Baileys API before leaving it out. The
  # picker asks on every load, and the request default (90s) is sized for a send, not
  # for a page an administrator is looking at.
  INSTALLATION_CHECK_TIMEOUT = 5

  def self.status(timeout: BAILEYS_REQUEST_OPTIONS[:timeout])
    if DEFAULT_URL.blank? || DEFAULT_API_KEY.blank?
      raise ProviderUnavailableError, 'Missing BAILEYS_PROVIDER_DEFAULT_URL or BAILEYS_PROVIDER_DEFAULT_API_KEY setup'
    end

    response = HTTParty.get(
      "#{DEFAULT_URL}/status",
      headers: { 'x-api-key' => DEFAULT_API_KEY },
      **BAILEYS_REQUEST_OPTIONS, timeout: timeout
    )

    unless response.success?
      Rails.logger.error response.body
      raise ProviderUnavailableError, 'Baileys API is unavailable'
    end

    response.parsed_response.deep_symbolize_keys
  rescue ProviderUnavailableError
    raise
  rescue StandardError => e
    Rails.logger.error e.message
    raise ProviderUnavailableError, 'Baileys API is unavailable'
  end

  # Whether this installation has a Baileys API connected: configured in the environment
  # and answering. Baileys is legacy, so a new inbox on it is only offered where one is
  # already running; an installation that never had it should not be shown it.
  def self.installed?
    status(timeout: INSTALLATION_CHECK_TIMEOUT)
    true
  rescue ProviderUnavailableError
    false
  end

  def setup_channel_provider
    # A session the server keeps rejecting can only be recovered by pairing a
    # fresh QR, but the provider always resumes stored creds when they exist —
    # so an operator asking to reconnect such a channel would just restart the
    # loop. Discard the dead session first; the setup below then gets a QR.
    # Gated on human intent by construction: this method only runs from
    # explicit setup/reconnect requests and from the connection-check job,
    # which is scheduled exclusively for channels that are `open`.
    disconnect_channel_provider if rejected_session?

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}",
      headers: api_headers,
      body: {
        clientName: DEFAULT_CLIENT_NAME,
        webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
        webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
        # TODO: Remove on Baileys v2, default will be false
        includeMedia: false,
        groupsEnabled: self.class.groups_enabled?,
        syncFullHistory: history_sync?
      }.compact.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  # Hot-loads an already-linked WhatsApp Web session extracted by the browser
  # extension: the Baileys API seeds the credentials and resumes the socket
  # without a QR. `session` is opaque impersonation credentials — never log it.
  # Not wrapped in `with_error_handling` (unlike setup_channel_provider): an
  # import failure surfaces to the client via the connection.update webhook
  # (provider_connection error), and recovery is a fresh QR setup, not a retry
  # of the import.
  def import_session(session:, candidate_index: 0)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/import-session",
      headers: api_headers,
      body: {
        session: session,
        candidateIndex: candidate_index,
        clientName: DEFAULT_CLIENT_NAME,
        webhookUrl: whatsapp_channel.inbox.callback_webhook_url,
        webhookVerifyToken: whatsapp_channel.provider_config['webhook_verify_token'],
        includeMedia: false,
        groupsEnabled: self.class.groups_enabled?,
        syncFullHistory: history_sync?
      }.compact.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  # Best-effort disconnect: we tell the Baileys API to drop the session and
  # move on regardless of the response. A stale or already-cleared session
  # (404), a Baileys API hiccup (5xx), or even a network error should not
  # block a provider conversion or channel teardown — the only point of
  # calling this is to avoid leaving a dangling session, not to gate the
  # caller's flow on that cleanup succeeding.
  # Reports the outcome instead of always claiming success. An explicit disconnect is an
  # operator waiting for an answer, and it is now the recovery path for a send stall:
  # returning true on a 500 or a read timeout meant the inbox was recorded as closed and
  # the stall warning cleared while the wedged socket was still there, which is the one
  # state where the UI stops telling anyone anything is wrong. The teardown callers that
  # legitimately do not care are the ones that catch it (see Channel::Whatsapp).
  # Whether this inbox reaches any Baileys provider at all: its own URL or the
  # installation's. Without either there is nothing to ask, and a request would go to an
  # empty host.
  def provider_configured?
    provider_url.present?
  end

  def disconnect_channel_provider
    response = HTTParty.delete(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}",
      headers: api_headers,
      **BAILEYS_REQUEST_OPTIONS
    )
    # 404 is the state being asked for, not a failure: the session is already gone, so
    # reporting it as one would abort a provider conversion, block the rejected-session
    # path in setup_channel_provider, and leave the modal offering Disconnect forever for
    # a connection that no longer exists.
    return true if response.success? || response.code == 404

    Rails.logger.warn("[WHATSAPP][BAILEYS] disconnect_channel_provider non-success status=#{response.code}")
    raise ProviderUnavailableError, outgoing_error(:disconnect_refused)
  rescue Whatsapp::Session::Errors::Error
    raise
  rescue StandardError => e
    Rails.logger.warn("[WHATSAPP][BAILEYS] disconnect_channel_provider failed: #{e.class}: #{e.message}")
    raise ProviderUnavailableError, outgoing_error(:disconnect_unreachable)
  end

  # Confirmed reconnect loop: the provider reported enough consecutive failed
  # reconnect cycles (quarantine strikes ride the reconnect_loop_detected
  # webhook and are persisted on provider_connection). An `open` channel never
  # qualifies — any healthy open clears the quarantine upstream, and the
  # strikes field is wiped by the next connection.update without it.
  def rejected_session?
    connection = whatsapp_channel.provider_connection || {}
    return false if connection['connection'] == 'open'

    connection.dig('quarantine', 'strikes').to_i >= RECONNECT_LOOP_RESET_STRIKES
  end

  def send_message(recipient_id, message)
    @message = message
    @recipient_id = recipient_id

    if @message.content_attributes[:is_reaction]
      @message_content = reaction_message_content
    elsif @message.attachments.present?
      @message_content = attachment_message_content.merge(reply_context)
    elsif @message.outgoing_content.present?
      @message_content = { text: @message.outgoing_content }.merge(reply_context)
      merge_mention_data
    else
      @message.update_under_lock!(is_unsupported: true)
      return
    end

    send_message_request
  end

  def send_template(phone_number, template_info); end

  def sync_templates; end

  def allow_group_creation?
    true
  end

  def create_group(subject, participants)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-create",
      headers: api_headers,
      body: { subject: subject, participants: participants }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.deep_symbolize_keys
  end

  def update_group_subject(group_jid, subject)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-subject",
      headers: api_headers,
      body: { jid: group_jid, subject: subject }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def update_group_description(group_jid, description)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-description",
      headers: api_headers,
      body: { jid: group_jid, description: description }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def update_group_picture(group_jid, image_base64)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/update-profile-picture",
      headers: api_headers,
      body: { jid: group_jid, image: image_base64 }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def update_group_participants(group_jid, participants, action)
    Array(participants).each do |participant|
      response = HTTParty.post(
        "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-participants",
        headers: api_headers,
        body: { jid: group_jid, participant: participant, action: action }.to_json,
        **BAILEYS_REQUEST_OPTIONS
      )

      raise ProviderUnavailableError unless process_response(response)

      check_participant_errors(response, action)
    end
  end

  def group_invite_code(group_jid)
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-invite-code",
      headers: api_headers,
      query: { jid: group_jid },
      format: :json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('data', 'inviteCode')
  end

  def revoke_group_invite(group_jid)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-revoke-invite",
      headers: api_headers,
      body: { jid: group_jid }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('data', 'inviteCode')
  end

  def group_join_requests(group_jid)
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-request-participants-list",
      headers: api_headers,
      query: { jid: group_jid },
      format: :json,
      **BAILEYS_REQUEST_OPTIONS
    )

    return [] if response.code == 403

    raise ProviderUnavailableError unless process_response(response)

    parsed = response.parsed_response
    parsed.is_a?(Array) ? parsed : (parsed&.dig('data') || [])
  end

  def handle_group_join_requests(group_jid, participants, action)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-request-participants-update",
      headers: api_headers,
      body: { jid: group_jid, participants: participants, action: action }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def group_leave(group_jid)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-leave",
      headers: api_headers,
      body: { jid: group_jid }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  PROPERTY_TO_SETTING = {
    ['announce', true] => 'announcement',
    ['announce', false] => 'not_announcement',
    ['restrict', true] => 'locked',
    ['restrict', false] => 'unlocked'
  }.freeze

  def group_setting_update(group_jid, property, enabled)
    setting = PROPERTY_TO_SETTING[[property, enabled]]
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-setting-update",
      headers: api_headers,
      body: { jid: group_jid, setting: setting }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def group_join_approval_mode(group_jid, mode)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-join-approval-mode",
      headers: api_headers,
      body: { jid: group_jid, mode: mode }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def group_member_add_mode(group_jid, mode)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-member-add-mode",
      headers: api_headers,
      body: { jid: group_jid, mode: mode }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)
  end

  def sync_group(conversation, soft: false)
    group_contact = conversation.contact
    inbox = conversation.inbox

    return true if conversation.contact_inbox&.group_left?

    metadata = group_metadata(group_contact.identifier)
    raise ProviderUnavailableError, 'Could not fetch group metadata' if metadata.blank?

    update_group_contact_info(group_contact, metadata)
    persist_group_settings(group_contact, metadata)
    persist_invite_code(group_contact) unless soft
    persist_pending_join_requests(group_contact, inbox) unless soft
    Channels::Whatsapp::BaileysUpdateGroupAvatarJob.perform_later(group_contact) unless soft

    participant_contacts = build_participant_contacts(metadata[:participants], inbox, skip_avatars: soft)
    sync_group_members(group_contact, participant_contacts)
    persist_sync_status(group_contact)

    true
  end

  def media_url(media_id)
    "#{provider_url}/media/#{media_id}"
  end

  def api_headers
    { 'x-api-key' => api_key, 'Content-Type' => 'application/json' }
  end

  def validate_provider_config?
    url = "#{provider_url}/status/auth"
    headers = api_headers
    response = credential_check_request { HTTParty.get(url, headers: headers, **BAILEYS_REQUEST_OPTIONS) }
    ensure_credential_verdict!(response)

    process_response(response)
  end

  def toggle_typing_status(typing_status, recipient_id:, **)
    @recipient_id = recipient_id
    status_map = {
      Events::Types::CONVERSATION_TYPING_ON => 'composing',
      Events::Types::CONVERSATION_RECORDING => 'recording',
      Events::Types::CONVERSATION_TYPING_OFF => 'paused'
    }

    response = HTTParty.patch(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/presence",
      headers: api_headers,
      body: {
        toJid: remote_jid,
        type: status_map[typing_status]
      }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def presence_subscribe(jids)
    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/presence-subscribe",
      headers: api_headers,
      body: { jids: Array(jids) }.to_json,
      **BAILEYS_SHORT_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.dig('data')
  end

  def update_presence(status)
    status_map = {
      'online' => 'available',
      'offline' => 'unavailable',
      'busy' => 'unavailable'
    }

    response = HTTParty.patch(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/presence",
      headers: api_headers,
      body: {
        type: status_map[status]
      }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def read_messages(messages, recipient_id:, **)
    @recipient_id = recipient_id

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/read-messages",
      headers: api_headers,
      body: {
        keys: messages.map { |message| message_key_for(message) }
      }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def unread_message(recipient_id, message)
    @recipient_id = recipient_id

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/chat-modify",
      headers: api_headers,
      body: {
        jid: remote_jid,
        mod: {
          markRead: false,
          lastMessages: [{
            key: message_key_for(message),
            messageTimestamp: message.content_attributes[:external_created_at]
          }]
        }
      }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def received_messages(recipient_id, messages)
    @recipient_id = recipient_id

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/send-receipts",
      headers: api_headers,
      body: {
        keys: messages.map { |message| message_key_for(message) }
      }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  # Whether this inbox asked for the history the phone already has. Off unless the operator
  # turned it on: the phone answers with everything it has, and an inbox that never asked
  # should not have a year of somebody else's conversations imported into it on the first
  # connect. Also what `syncFullHistory` is set from, so the setting decides what the socket
  # asks for as well as what is kept.
  def history_sync?
    ActiveModel::Type::Boolean.new.cast(whatsapp_channel.provider_config&.dig('history_sync')).present?
  end

  # Asks the phone for what came before a chat's oldest stored message. WhatsApp can only
  # walk backwards, so a request needs a message to walk back from: with nothing stored for
  # this contact there is no anchor and nothing to ask.
  #
  # The answer is not this call's. The phone acknowledges and replies later on the
  # `messaging-history.set` webhook, typed ON_DEMAND, and only if it is awake to answer at
  # all; `count` is a hint the phone routinely overshoots.
  def request_history(contact, count: nil, before: nil)
    anchor = before || oldest_stored_message(contact)
    jid = history_jid(contact)
    return false if anchor.blank? || anchor.source_id.blank? || jid.blank?

    response = HTTParty.post(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/fetch-message-history",
      headers: api_headers,
      body: {
        count: (count || HISTORY_REQUEST_COUNT).to_i.clamp(1, HISTORY_REQUEST_COUNT),
        oldestMsgKey: { id: anchor.source_id, remoteJid: jid, fromMe: anchor.outgoing? },
        oldestMsgTimestamp: history_anchor_timestamp(anchor)
      }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def get_profile_pic(jid)
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/profile-picture-url",
      headers: api_headers,
      query: { jid: jid },
      format: :json,
      **BAILEYS_SHORT_REQUEST_OPTIONS
    )

    return nil unless process_response(response)

    response.parsed_response
  end

  def group_metadata(group_jid)
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/group-metadata",
      headers: api_headers,
      query: { jid: group_jid },
      format: :json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    response.parsed_response&.deep_symbolize_keys
  end

  # `deadline` is how long the caller can afford to wait: `:hint` for a lookup that only shows a
  # hint and treats silence as "I do not know" (the compose warning), `:request` for one a web
  # request waits on (starting a conversation), `:provider` for a job that can wait as long as
  # the provider may take (the recheck). One call per ceiling, each naming its own, so the fences
  # in baileys_request_options_spec and request_ceilings_spec read which one is in force.
  def on_whatsapp(recipient_id, deadline: :provider)
    @recipient_id = recipient_id
    url = "#{provider_url}/connections/#{whatsapp_channel.phone_number}/on-whatsapp"
    body = { jids: [remote_jid] }.to_json

    response = case deadline
               when :hint then HTTParty.post(url, headers: api_headers, body: body, **BAILEYS_SHORT_REQUEST_OPTIONS)
               when :request then HTTParty.post(url, headers: api_headers, body: body, **BAILEYS_IN_REQUEST_OPTIONS)
               else HTTParty.post(url, headers: api_headers, body: body, **BAILEYS_REQUEST_OPTIONS)
               end

    raise ProviderUnavailableError unless process_response(response)

    result = response.parsed_response
    result = result.is_a?(Array) ? result : result&.dig('data')
    result&.first || { 'jid' => remote_jid, 'exists' => false }
  end

  def delete_message(recipient_id, message)
    @recipient_id = recipient_id

    response = HTTParty.delete(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/messages",
      headers: api_headers,
      body: {
        jid: remote_jid,
        key: message_key_for(message)
      }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  def edit_message(recipient_id, message, new_content)
    @recipient_id = recipient_id

    response = HTTParty.patch(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/messages",
      headers: api_headers,
      body: {
        jid: remote_jid,
        key: message_key_for(message),
        messageContent: { text: new_content }
      }.to_json,
      **BAILEYS_REQUEST_OPTIONS
    )

    raise ProviderUnavailableError unless process_response(response)

    true
  end

  # Reach-out time-lock state for this connection. Read-only MEX query (safe on a restricted
  # account; never counts as a "reach out"). 404 = number not connected on the provider, which
  # is "unknown" and NOT "unrestricted", so we return nil for the caller to leave the banner
  # state untouched. Deliberately NOT wrapped in with_error_handling: that helper marks the
  # connection `close` on any error, which would be catastrophic for a diagnostic GET.
  def fetch_reachout_timelock
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/reachout-timelock",
      headers: api_headers,
      format: :json,
      **BAILEYS_SHORT_REQUEST_OPTIONS
    )

    return nil if response.code == 404
    return nil unless process_response(response)

    data = response.parsed_response&.deep_symbolize_keys&.dig(:data) || {}
    {
      is_active: data[:isActive] || false,
      time_enforcement_ends: data[:timeEnforcementEnds],
      enforcement_type: data[:enforcementType]
    }.compact
  end

  # Send-side health for this connection. The reason it exists: setup_channel_provider is
  # not a health check for sending. On an already-registered connection it only sends a
  # presence update, which does not go through the provider's keystore — so it succeeds
  # against a socket whose sends are wedged, which is exactly the state we need to catch.
  #
  # nil means "unknown" (404 / error): the caller must leave the existing state alone
  # rather than treat a failed lookup as healthy. Deliberately NOT wrapped in
  # with_error_handling, matching the other diagnostic GETs — that helper marks the
  # connection `close` on any error, which would be perverse for a health probe.
  def fetch_send_health
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/health",
      headers: api_headers,
      format: :json,
      **BAILEYS_SHORT_REQUEST_OPTIONS
    )

    return nil if response.code == 404
    return nil unless process_response(response)

    data = response.parsed_response&.deep_symbolize_keys&.dig(:data) || {}
    {
      send_state: data[:sendState],
      consecutive_send_timeouts: data[:consecutiveSendTimeouts],
      last_send_completed_ago_ms: data[:lastSendCompletedAgoMs],
      last_outgoing_ack_ago_ms: data[:lastOutgoingAckAgoMs]
    }.compact
  end

  # New-chat message cap (quota) for this connection. Read-only MEX query with the same 404
  # semantics as fetch_reachout_timelock (404 = not connected = unknown -> nil, don't clear the
  # banner). Returns the raw NewChatMessageCapInfo (already snake_case from the provider); the
  # model slices it to the UI-relevant keys when persisting.
  def fetch_new_chat_cap
    response = HTTParty.get(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/new-chat-cap",
      headers: api_headers,
      format: :json,
      **BAILEYS_SHORT_REQUEST_OPTIONS
    )

    return nil if response.code == 404
    return nil unless process_response(response)

    response.parsed_response&.deep_symbolize_keys&.dig(:data)
  end

  private

  # The chat as WhatsApp addresses it. Rebuilt from what the contact holds rather than
  # stored: the original `remoteJid` is not kept on the message row, and the identifier the
  # contact carries is the same value it was taken from.
  def history_jid(contact)
    contact_inbox = contact.contact_inboxes.find_by(inbox_id: whatsapp_channel.inbox.id)
    return if contact_inbox.blank?

    return "#{contact_inbox.source_id}@g.us" if contact.group_type_group?
    return contact.identifier if contact.identifier.to_s.end_with?('@lid')

    phone = contact.phone_number.to_s.delete('+')
    "#{phone}@s.whatsapp.net" if phone.present?
  end

  def oldest_stored_message(contact)
    Message.where(conversation_id: contact.conversations.where(inbox_id: whatsapp_channel.inbox.id).select(:id))
           .where.not(source_id: nil)
           .reorder(created_at: :asc)
           .first
  end

  # The provider's own clock for the anchor when we have it, since that is the number the
  # phone indexed the message by.
  #
  # In milliseconds: the field the bridge hands this to is `oldestMsgTimestampMs`, while
  # both clocks we read from are in seconds. Baileys' own example and every port of it
  # pass the raw `messageTimestamp` here, so the mismatch is widespread and quiet -- the
  # server answers the key and never complains about the timestamp.
  def history_anchor_timestamp(message)
    seconds = message.content_attributes['external_created_at'].presence || message.created_at.to_i
    seconds.to_i * 1000
  end

  def provider_url
    whatsapp_channel.provider_config['provider_url'].presence || DEFAULT_URL
  end

  def api_key
    whatsapp_channel.provider_config['api_key'].presence || DEFAULT_API_KEY
  end

  def reaction_message_content
    reply_to = Message.find(@message.in_reply_to)
    {
      react: {
        key: message_key_for(reply_to),
        text: @message.outgoing_content
      }
    }
  end

  def reply_context
    reply_to_external_id = @message.content_attributes[:in_reply_to_external_id]
    return {} if reply_to_external_id.blank?

    reply_to_message = @message.conversation.messages.find_by(source_id: reply_to_external_id)
    return {} unless reply_to_message

    {
      quotedMessage: {
        key: message_key_for(reply_to_message),
        message: quoted_message_content(reply_to_message)
      }
    }
  end

  def message_key_for(message)
    {
      id: message.source_id,
      remoteJid: remote_jid,
      fromMe: message.message_type == 'outgoing',
      participant: group_participant_jid(message)
    }.compact
  end

  def group_participant_jid(message)
    return unless remote_jid.ends_with?('@g.us')
    return if message.message_type == 'outgoing'

    message.sender&.identifier
  end

  def quoted_message_content(message)
    if message.attachments.present?
      attachment = message.attachments.first
      case attachment.file_type
      when 'image'
        { imageMessage: { caption: message.content } }
      when 'video'
        { videoMessage: { caption: message.content } }
      when 'audio'
        { audioMessage: {} }
      when 'file'
        { documentMessage: { caption: message.content, fileName: attachment.file.filename.to_s } }
      else
        { conversation: message.content.to_s }
      end
    else
      { conversation: message.content.to_s }
    end
  end

  def attachment_message_content # rubocop:disable Metrics/MethodLength
    attachment = @message.attachments.first
    buffer = attachment_to_base64(attachment)

    content = {
      fileName: attachment.file.filename,
      caption: @message.outgoing_content
    }
    case attachment.file_type
    when 'image'
      content[:image] = buffer
    when 'audio'
      content[:audio] = buffer
      content[:ptt] = true if voice_note_attachment?(attachment)
    when 'file'
      content[:document] = buffer
      content[:mimetype] = attachment.file.content_type
    when 'sticker'
      content[:sticker] = buffer
    when 'video'
      content[:video] = buffer
    end

    content.compact
  end

  # `is_recorded_audio` is the legacy fazer.ai meta key (transcode pipeline and old messages).
  def voice_note_attachment?(attachment)
    meta = attachment.meta || {}
    meta['is_voice_message'].present? || meta['is_recorded_audio'].present?
  end

  def send_message_request
    message_id = reserve_source_id

    response = post_send_message(
      "#{provider_url}/connections/#{whatsapp_channel.phone_number}/send-message",
      headers: api_headers,
      body: {
        jid: remote_jid,
        messageContent: @message_content,
        # baileys-api uses this as an idempotency key. Reactions UPDATE a single
        # Message row in place across toggle/replace/remove cycles, so reusing
        # only `id` would make every follow-up send hit the cached response and
        # never reach WhatsApp. Suffixing with updated_at gives each send a fresh
        # key while still letting Sidekiq retries of the same attempt dedupe.
        chatwootMessageId: "#{@message.id}:#{@message.updated_at.to_f}",
        messageId: message_id
      }.to_json
    )

    raise_send_error(response) unless response.success?

    update_external_created_at(response)
    response.parsed_response.dig('data', 'key', 'id')
  end

  # A transport failure never reaches raise_send_error, because there is no response to
  # classify — it escapes as itself, outside the session hierarchy, so SendReplyJob's
  # retry_on never sees it and the job dies in the dead set with the bubble still reading
  # "sent". That is the exact silent failure this change exists to remove.
  #
  # Rescued as a CLASS rather than as a list of exception types, which is why nothing but
  # the HTTP call lives in here: an enumerated list is a promise to have thought of every
  # way a socket can fail, and it will be wrong (Net::WriteTimeout on a large media body,
  # OpenSSL::SSL::SSLError on a handshake, whatever the next TLS or HTTP gem raises).
  # Anything StandardError can be here is a transport failure by construction.
  # The ceiling goes on this call and not on the caller, so that the one HTTParty call on the
  # send path cannot be reached without it, and it goes AFTER the forwarded keywords so a
  # caller cannot quietly raise it. The constant's 90s is the number this call chose first:
  # above the API's own 45s send deadline plus its slower paths (audio transcoding, media
  # upload) and above its proxy's 75s cut, so what comes back is its structured 504/503 and
  # not a bare Net::ReadTimeout. The ceiling above it is the per-channel outgoing lock
  # (BaileysHelper::CHANNEL_LOCK_ON_OUTGOING_MESSAGE_TIMEOUT, 130s), which every other send on
  # the inbox queues behind.
  def post_send_message(url, **)
    HTTParty.post(url, **, **BAILEYS_REQUEST_OPTIONS)
  rescue StandardError => e
    raise_transport_error(e)
  end

  # The list of failures that cannot have put a byte on the wire, and the predicate that reads
  # it, come from Whatsapp::TransportFailure. What stays here is what to raise, because this
  # provider answers differently from the other three: a possibly-delivered send here is
  # retryable, since the reserved message id makes a second attempt duplicate-safe, and the
  # providers that reserve nothing must not retry one at all.
  def raise_transport_error(error)
    Rails.logger.error "[WHATSAPP][BAILEYS] transport failure on send: #{error.class}: #{error.message}"

    raise ProviderUnavailableError, outgoing_error(:provider_unreachable) if never_transmitted?(error)

    raise SendTimeoutError, outgoing_error(:send_timed_out)
  end

  # Every non-2xx used to collapse into a bare ProviderUnavailableError, which made it
  # impossible to tell "the connection is wedged" from "this message can never be sent"
  # — so the job retried both and buried both in the dead set. Only the codes whose
  # meaning is unambiguous are mapped; anything else keeps the old behaviour rather than
  # risk marking a message permanently failed on a guess.
  def raise_send_error(response)
    Rails.logger.error response.body

    case response.code
    when 409 then raise_conflict_send_error(response)
    when 503 then raise_unavailable_send_error(response)
    when 504
      raise SendTimeoutError, outgoing_error(:send_timed_out)
    when 413
      raise Whatsapp::Session::Errors::MediaTooLarge, outgoing_error(:media_too_large)
    when 422
      raise Whatsapp::Session::Errors::InvalidPayload, outgoing_error(:invalid_payload)
    else
      # Reasoned, not bare: SendReplyJob persists this message as external_error when the
      # retries run out, and a bare raise makes that message the Ruby class name. The
      # agent then reads an internal constant where the reason should be.
      raise ProviderUnavailableError, outgoing_error(:provider_error)
    end
  end

  # The two statuses a send can come back with where the status alone is not the answer:
  # each covers two conditions that need opposite handling, and a header tells them apart.
  def raise_conflict_send_error(response)
    raise SendOutcomeUnknownError, outgoing_error(:send_outcome_unknown) if indeterminate_send?(response)

    raise MessageAlreadyProcessingError
  end

  # A wedged connection must NOT be marked 'close' (see NON_CHANNEL_DOWN_CODES): that
  # would drop it out of the very health-check cycle that detects the stall, and 503 is
  # where the whole episode settles, since every send after the third timeout gets it.
  # But an outage and a draining proxy answer 503 too, and reading those as a stall leaves
  # a genuinely dead channel recorded as open, skipping the reconnect it needed.
  def raise_unavailable_send_error(response)
    raise SendStalledError, outgoing_error(:send_stalled) if stalled_send?(response)

    raise ProviderUnavailableError, outgoing_error(:provider_error)
  end

  def outgoing_error(key)
    I18n.t("#{OUTGOING_ERRORS_SCOPE}.#{key}")
  end

  def indeterminate_send?(response)
    response.headers['x-baileys-idempotency-state'] == 'indeterminate'
  end

  def stalled_send?(response)
    response.headers['x-baileys-send-state'] == 'stalled'
  end

  # The WhatsApp message id this send will use, picked here instead of letting Baileys generate it.
  # `source_id` can only be written from the response, so a send whose response never arrives (socket
  # drop, read timeout, worker restart) leaves us with no way to recognize the `messages.upsert` echo
  # of our own message — it lands as a fresh "sent from the phone" message. Reserving the id up front
  # closes that window, and a Sidekiq retry reuses it so WhatsApp still sees a single message.
  # Shape mirrors Baileys' generateMessageIDV2: the "3EB0" prefix followed by 18 uppercase hex chars.
  #
  # The whole read-or-generate runs under the row lock, which re-reads the row: this send may have
  # been queued behind the channel lock for minutes, and a reaction toggle in the meantime clears the
  # reservation precisely to force a fresh id — sending under the id we loaded before waiting would
  # resend the previous reaction and leave its echo unmatchable.
  #
  # Written with `update_columns`: the reservation is bookkeeping for a send that has not happened
  # yet, so it must not fire `message.updated` (cable, webhooks, agent bots, search reindex) nor bump
  # `updated_at`, which the idempotency key above is built from — a retry has to reuse the same key.
  def reserve_source_id
    @message.with_lock do
      next @message.pending_source_id if @message.pending_source_id.present?

      id = "3EB0#{SecureRandom.hex(9).upcase}"
      @message.pending_source_id = id
      @message.update_columns(content_attributes: @message.content_attributes) # rubocop:disable Rails/SkipsModelValidations
      id
    end
  end

  def process_response(response)
    Rails.logger.error response.body unless response.success?
    response.success?
  end

  def check_participant_errors(response, action)
    return unless action.in?(%w[demote remove])

    results = response.parsed_response
    return unless results.is_a?(Array)

    failed = results.find { |r| r['status'].to_s == '406' }
    return if failed.blank?

    raise GroupParticipantNotAllowedError, 'group_creator_not_modifiable'
  end

  def merge_mention_data
    return if @message.content.blank?

    mention_data = Whatsapp::MentionConverterService.extract_mentions_for_whatsapp(@message.content, whatsapp_channel.account)
    @message_content.merge!(mention_data) if mention_data.present?

    # Replace @DisplayName with @lid/@phone in text so Baileys can match mentions
    @message_content[:text] = Whatsapp::MentionConverterService.replace_mentions_in_outgoing_text(
      @message.content, @message_content[:text], whatsapp_channel.account
    )
  end

  def remote_jid
    return @recipient_id if @recipient_id.ends_with?('@lid')
    return @recipient_id if @recipient_id.ends_with?('@g.us')

    "#{@recipient_id.delete('+')}@s.whatsapp.net"
  end

  def update_external_created_at(response)
    timestamp = response.parsed_response.dig('data', 'messageTimestamp')
    return unless timestamp

    external_created_at = baileys_extract_message_timestamp(timestamp)
    @message.update_under_lock!(external_created_at: external_created_at)
  end

  def build_participant_contacts(participants, inbox, skip_avatars: false)
    return [] if participants.blank?

    participants.filter_map do |participant|
      contact = find_or_create_participant_contact(participant, inbox)
      next if contact.blank?

      try_update_participant_avatar(contact) unless skip_avatars
      { contact: contact, admin: participant[:admin] }
    end
  end

  # `group_contact` was read at the top of `sync_group`, before the metadata call, and every
  # write in this sync merges into that copy. Four network calls happen along the way, so the
  # merge has to go against the row as it is now. The name travels with it because taking the
  # row lock reloads the record and would drop an assignment made out here.
  def update_group_contact_info(group_contact, metadata)
    attributes = {}
    attributes[:name] = metadata[:subject] if metadata[:subject].present? && group_contact.name != metadata[:subject]

    group_contact.merge_json_column!(
      :additional_attributes,
      attributes: attributes,
      merge: {
        'description' => metadata[:desc].presence,
        'owner' => metadata[:owner],
        'owner_pn' => metadata[:ownerPn].presence
      }
    )
  end

  def sync_group_members(group_contact, participant_contacts)
    return if participant_contacts.blank?

    new_contact_ids = participant_contacts.filter_map do |entry|
      role = entry[:admin].in?(%w[admin superadmin]) ? :admin : :member
      member = GroupMember.find_or_initialize_by(group_contact: group_contact, contact: entry[:contact])
      member.assign_attributes(role: role, is_active: true)
      member.save! if member.changed?
      entry[:contact].id
    end

    group_contact.group_memberships.active.where.not(contact_id: new_contact_ids).find_each do |member|
      member.update!(is_active: false)
    end
  end

  TRACKED_GROUP_SETTINGS = {
    announce: 'announce',
    restrict: 'restrict',
    joinApprovalMode: 'join_approval_mode',
    memberAddMode: 'member_add_mode'
  }.freeze

  def persist_group_settings(group_contact, metadata)
    settings = TRACKED_GROUP_SETTINGS.each_with_object({}) do |(api_key, attr_key), hash|
      hash[attr_key] = metadata[api_key] if metadata.key?(api_key)
    end
    return if settings.blank?

    group_contact.merge_json_column!(:additional_attributes, merge: settings)
  end

  # `group_left` is not cleared here. It is per inbox now (see WhatsappGroupMembership),
  # and a sync only ever reaches this point for an inbox that has not left, so there was
  # nothing for it to clear; rejoining is what clears it, and only the rejoin path knows
  # that happened.
  def persist_sync_status(group_contact)
    group_contact.merge_json_column!(:additional_attributes, merge: { 'group_last_synced_at' => Time.current.to_i })
  end

  def persist_invite_code(group_contact)
    code = group_invite_code(group_contact.identifier)
    return if code.blank?

    group_contact.merge_json_column!(:additional_attributes, merge: { 'invite_code' => code })
  rescue StandardError => e
    Rails.logger.error "Failed to fetch invite code for group #{group_contact.identifier}: #{e.message}"
  end

  def persist_pending_join_requests(group_contact, inbox)
    raw_requests = group_join_requests(group_contact.identifier)
    requests = raw_requests.filter_map do |req|
      contact = find_or_create_participant_contact({ id: req['jid'], phoneNumber: req['phone_number'] }, inbox)
      next if contact.blank?

      { 'jid' => req['jid'], 'contact_id' => contact.id, 'request_time' => req['request_time'] }
    end

    group_contact.merge_json_column!(:additional_attributes, merge: { 'pending_join_requests' => requests })
  rescue StandardError => e
    Rails.logger.error "Failed to fetch pending join requests for group #{group_contact.identifier}: #{e.message}"
  end

  public

  def try_update_group_avatar(group_contact, force: false)
    if force
      reset_avatar_state(group_contact)
    elsif group_contact.avatar.attached?
      return
    end

    response = get_profile_pic(group_contact.identifier)
    profile_pic_url = response&.dig('data', 'profilePictureUrl')
    ::Avatar::AvatarFromUrlJob.perform_later(group_contact, profile_pic_url) if profile_pic_url
  rescue StandardError => e
    Rails.logger.error "Failed to update avatar for group #{group_contact.identifier}: #{e.message}"
  end

  private

  def reset_avatar_state(group_contact)
    group_contact.avatar.purge if group_contact.avatar.attached?
    group_contact.update_avatar_sync_markers!(remove: Whatsapp::Session::AvatarSync::MARKERS)
  end

  def try_update_participant_avatar(contact)
    return if contact.avatar.attached?

    phone = contact.phone_number&.delete('+')
    return if phone.blank?

    profile_pic_url = fetch_profile_picture_url(phone)
    ::Avatar::AvatarFromUrlJob.perform_later(contact, profile_pic_url) if profile_pic_url
  rescue StandardError => e
    Rails.logger.error "Failed to update avatar for contact #{contact.id}: #{e.message}"
  end

  def fetch_profile_picture_url(phone_number)
    jid = "#{phone_number}@s.whatsapp.net"
    response = get_profile_pic(jid)
    response&.dig('data', 'profilePictureUrl')
  end

  def find_or_create_participant_contact(participant, inbox)
    lid = extract_lid_from_participant(participant)
    phone = extract_phone_from_participant(participant)
    identifier = lid ? "#{lid}@lid" : nil
    source_id = lid || phone

    return nil if source_id.blank?

    Whatsapp::ContactInboxConsolidationService.new(
      inbox: inbox, phone: phone, lid: lid, identifier: identifier
    ).perform

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: {
        name: phone,
        phone_number: ("+#{phone}" if phone),
        identifier: identifier
      }
    ).perform

    return nil if contact_inbox.blank?

    update_participant_contact_info(contact_inbox.contact, phone, identifier)
  end

  def update_participant_contact_info(contact, phone, identifier)
    update_params = {
      phone_number: ("+#{phone}" if phone && contact.phone_number.blank?),
      identifier: (identifier if identifier && contact.identifier.blank?)
    }.compact

    contact.update!(update_params) if update_params.present?
    contact
  end

  def extract_lid_from_participant(participant)
    return nil if participant[:id].blank?

    jid_part, jid_suffix = participant[:id].split('@')
    jid_part if jid_suffix == 'lid' && jid_part.match?(/^\d+$/)
  end

  def extract_phone_from_participant(participant)
    return nil if participant[:phoneNumber].blank?

    phone = participant[:phoneNumber].split('@').first
    phone if phone.match?(/^\d+$/)
  end

  private_class_method def self.with_error_handling(*method_names)
    method_names.each do |method_name|
      original_method = instance_method(method_name)

      define_method("#{method_name}_without_error_handling") do |*args, **kwargs, &block|
        original_method.bind_call(self, *args, **kwargs, &block)
      end

      define_method(method_name) do |*args, **kwargs, &block|
        original_method.bind_call(self, *args, **kwargs, &block)
      rescue StandardError => e
        handle_channel_error unless channel_error_exempt?(e)
        raise e
      end
    end
  end

  # Errors that do NOT mean the connection is down, so they must not mark it 'close'.
  # BaileysConnectionCheckSchedulerJob only enqueues channels whose connection is 'open',
  # so marking it drops the channel out of the health-check cycle entirely, and only a
  # webhook or a human puts it back.
  #
  # Two groups. The first says something about this message, not the connection: a
  # rejected attachment or an unknown outcome tells us nothing about the socket. The
  # second is the send stall itself — the connection is receiving and answering health
  # checks, only sending is wedged, and marking it 'close' would remove it from the very
  # cycle that detects that state while POST /connections cannot repair it anyway (on a
  # registered connection it only sends a presence update, which does not touch the
  # keystore). The provider recovers this on its own.
  # Matched on the wire code, not on class identity, for the reason
  # Whatsapp::Session::Errors::Error#retryable? gives: a constant holding another file's
  # class keeps the object from before the last reload, and `is_a?` against it then
  # answers false without saying why. Two of these classes live in errors.rb, so a list
  # of classes frozen here would be exactly that trap.
  NON_CHANNEL_DOWN_CODES = %w[
    message_already_processing
    send_outcome_unknown
    send_stalled
    timeout
    media_too_large
    invalid_payload
  ].freeze

  def channel_error_exempt?(error)
    return false unless error.respond_to?(:code)

    NON_CHANNEL_DOWN_CODES.include?(error.code)
  end

  def handle_channel_error
    whatsapp_channel.update_provider_connection!(connection: 'close')

    return if @handling_error

    @handling_error = true
    begin
      setup_channel_provider_without_error_handling
    rescue StandardError => e
      Rails.logger.error "Failed to reconnect channel after error: #{e.message}"
    ensure
      @handling_error = false
    end
  end

  # `on_whatsapp` is left out on purpose: it is a read whose every caller treats a failure as
  # "unknown" (the contact builder, the compose form's warning, the no-WhatsApp recheck), so a
  # 500 on one number lookup must not mark a working session 'close' and show the agent a
  # disconnected inbox. A connection that is really down is caught by the connection check.
  with_error_handling :setup_channel_provider,
                      :send_message,
                      :toggle_typing_status,
                      :presence_subscribe,
                      :update_presence,
                      :read_messages,
                      :unread_message,
                      :received_messages,
                      :group_metadata,
                      :sync_group,
                      :delete_message,
                      :edit_message,
                      :group_leave,
                      :group_setting_update,
                      :group_join_approval_mode,
                      :group_member_add_mode
end
