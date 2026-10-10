class Webhooks::WhatsappEventsJob < MutexApplicationJob
  queue_as :low
  # Retry budget (19 × 2s = 38s) must exceed the 30s lock TTL set in `perform`, otherwise
  # a webhook that arrives just after the lock is acquired can exhaust retries before the
  # holder finishes and silently drop its message.
  retry_on LockAcquisitionError, wait: 2.seconds, attempts: 20

  def perform(params = {})
    channel = find_channel_from_whatsapp_business_payload(params)

    if channel_is_inactive?(channel)
      Rails.logger.warn("Inactive WhatsApp channel: #{channel&.phone_number || "unknown - #{params[:phone_number]}"}")
      return
    end

    sender_id = contact_sender_id(params)
    return process_events(channel, params) if sender_id.blank?

    # Album uploads arrive as separate concurrent webhooks. Serialize per (inbox, contact)
    # so the first webhook creates the conversation and the rest append to it.
    # 30s TTL covers the attachment download + transaction — the default 1s expires
    # mid-processing and lets a concurrent webhook re-acquire before the first commit.
    key = format(::Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: channel.inbox.id, sender_id: sender_id)
    with_lock(key, 30.seconds) do
      process_events(channel, params, sender_id)
    end
  end

  def process_events(channel, params, locked_sender_id = nil)
    if message_echo_event?(params)
      handle_message_echo(channel, params)
    else
      handle_message_events(channel, params, locked_sender_id)
    end
  end

  # Detects if the webhook is an SMB message echo event (message sent from WhatsApp Business app)
  # This is part of WhatsApp coexistence feature where businesses can respond from both
  # Chatwoot and the WhatsApp Business app, with messages synced to Chatwoot.
  #
  # Regular message payload (field: "messages"):
  # {
  #   "entry": [{
  #     "changes": [{
  #       "field": "messages",
  #       "value": {
  #         "contacts": [{ "wa_id": "919745786257", "profile": { "name": "Customer" } }],
  #         "messages": [{ "from": "919745786257", "id": "wamid...", "text": { "body": "Hello" } }]
  #       }
  #     }]
  #   }]
  # }
  #
  # Echo message payload (field: "smb_message_echoes"):
  # {
  #   "entry": [{
  #     "changes": [{
  #       "field": "smb_message_echoes",
  #       "value": {
  #         "contacts": [{
  #           "wa_id": "919745786257", "user_id": "IN.2081978709342942",
  #           "parent_user_id": "IN.ENT.11815799212886844830"
  #         }],
  #         "message_echoes": [{
  #           "from": "971545296927", "to": "919745786257", "to_user_id": "IN.2081978709342942",
  #           "to_parent_user_id": "IN.ENT.11815799212886844830",
  #           "id": "wamid...", "text": { "body": "Hi" }
  #         }]
  #       }
  #     }]
  #   }]
  # }
  #
  # Key differences:
  # - field: "smb_message_echoes" instead of "messages"
  # - message_echoes[] instead of messages[]
  # - "from" is the business number; "to" is the contact phone and can be omitted
  # - "to_user_id" is the contact BSUID; "to_parent_user_id" is included when parent BSUIDs are enabled
  # - contacts[] contains the same contact identifiers
  def message_echo_event?(params)
    params.dig(:entry, 0, :changes, 0, :field) == 'smb_message_echoes'
  end

  def handle_message_echo(channel, params)
    Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params, outgoing_echo: true).perform
  end

  def handle_message_events(channel, params, locked_sender_id = nil)
    case channel.provider
    when 'whatsapp_cloud'
      service_params = { inbox: channel.inbox, params: params }
      service_params[:locked_sender_id] = locked_sender_id if locked_sender_id.present?
      Whatsapp::IncomingMessageWhatsappCloudService.new(**service_params).perform
    else
      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    end
  end

  private

  # Echo payloads reverse the fields — `from` is the business number and `to` is the contact.
  # Returns nil for status-only webhooks so they bypass the lock.
  def contact_sender_id(params)
    value = params.dig(:entry, 0, :changes, 0, :value) || params
    return contact_sender_id_from_message_echoes(value[:message_echoes]) if value[:message_echoes].present?

    contact_sender_id_from_messages(value[:messages], value[:contacts])
  end

  # Echo payloads are outbound messages from the WhatsApp Business app, so `to`
  # points to the contact. Prefer parent BSUID when present so payloads that have
  # both regular+parent BSUIDs serialize with parent-BSUID-only payloads.
  def contact_sender_id_from_message_echoes(message_echoes)
    message = message_echoes&.first
    return if message.blank?

    [message[:to_parent_user_id], message[:to_user_id], message[:to]].compact_blank.first
  end

  # Regular inbound payloads are sent by the contact, so `from` points to the
  # contact. Prefer parent BSUID when present so payloads that have both
  # regular+parent BSUIDs serialize with parent-BSUID-only payloads.
  def contact_sender_id_from_messages(messages, contacts)
    message = messages&.first
    return if message.blank?
    return contact_sender_id_from_system_message(message) if message[:type] == 'system'

    contact = contacts&.first || {}

    [
      message[:from_parent_user_id],
      contact[:parent_user_id],
      message[:from_user_id],
      contact[:user_id],
      message[:from]
    ].compact_blank.first
  end

  # Identity changes arrive on the existing messages subscription as system messages. Lock on
  # the newly introduced identity so the lifecycle event serializes with the first inbound
  # message that uses it. The rotation service acquires the remaining current-identifier locks.
  def contact_sender_id_from_system_message(message)
    system = message[:system] || {}

    [system[:parent_user_id], system[:user_id], system[:wa_id], message[:from]].compact_blank.first
  end

  def channel_is_inactive?(channel)
    return true if channel.blank?
    # Only skip for embedded signup when reauth is required; manual flow uses API keys and should still receive webhooks
    return true if channel.reauthorization_required? && embedded_signup_channel?(channel)
    return true unless channel.account.active?

    false
  end

  def embedded_signup_channel?(channel)
    (channel.provider_config || {}).to_h['source'] == 'embedded_signup'
  end

  def find_channel_by_url_param(params)
    return unless params[:phone_number]

    Channel::Whatsapp.find_by(phone_number: params[:phone_number])
  end

  def find_channel_from_whatsapp_business_payload(params)
    # for the case where facebook cloud api support multiple numbers for a single app
    # https://github.com/chatwoot/chatwoot/issues/4712#issuecomment-1173838350
    # we will give priority to the phone_number in the payload
    return get_channel_from_wb_payload(params) if params[:object] == 'whatsapp_business_account'

    find_channel_by_url_param(params)
  end

  def get_channel_from_wb_payload(wb_params)
    metadata = wb_params[:entry].first[:changes].first.dig(:value, :metadata) || {}
    Whatsapp::WebhookChannelFinderService.new(
      display_phone_number: metadata[:display_phone_number],
      phone_number_id: metadata[:phone_number_id]
    ).perform
  end
end

Webhooks::WhatsappEventsJob.prepend_mod_with('Webhooks::WhatsappEventsJob')
