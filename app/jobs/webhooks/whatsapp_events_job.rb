class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    channel = find_channel_from_whatsapp_business_payload(params)

    if channel_is_inactive?(channel)
      Rails.logger.warn("Inactive WhatsApp channel: #{channel&.phone_number || "unknown - #{params[:phone_number]}"}")
      return
    end

    if message_echo_event?(params)
      handle_message_echo(channel, params)
    else
      handle_message_events(channel, params)
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
  #         "message_echoes": [{ "from": "971545296927", "to": "919745786257", "id": "wamid...", "text": { "body": "Hi" } }]
  #       }
  #     }]
  #   }]
  # }
  #
  # Key differences:
  # - field: "smb_message_echoes" instead of "messages"
  # - message_echoes[] instead of messages[]
  # - "from" is the business number, "to" is the contact (reversed from regular messages)
  # - No "contacts" array in echo payload
  def message_echo_event?(params)
    params.dig(:entry, 0, :changes, 0, :field) == 'smb_message_echoes'
  end

  def handle_message_echo(channel, params)
    Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params, outgoing_echo: true).perform
  end

  def handle_message_events(channel, params)
    if call_event?(params)
      handle_call_events(channel, params)
      return
    end

    if call_permission_reply?(params)
      handle_call_permission_reply(channel, params)
      return
    end

    case channel.provider
    when 'whatsapp_cloud'
      Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params).perform
    else
      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    end
  end

  def handle_call_events(channel, params)
    Whatsapp::IncomingCallService.new(
      inbox: channel.inbox,
      params: extract_call_params(params)
    ).perform
  end

  def call_event?(params)
    params.dig(:entry, 0, :changes, 0, :field) == 'calls'
  end

  def call_permission_reply?(params)
    message = params.dig(:entry, 0, :changes, 0, :value, :messages, 0)
    message&.dig(:type) == 'interactive' && message&.dig(:interactive, :type) == 'call_permission_reply'
  end

  def handle_call_permission_reply(channel, params)
    value = params.dig(:entry, 0, :changes, 0, :value)
    message = value&.dig(:messages, 0)
    reply = message&.dig(:interactive, :call_permission_reply)
    return unless reply

    from_number = message[:from]
    accepted = reply[:response] == 'accept'

    Rails.logger.info "[WHATSAPP CALL] call_permission_reply from=#{from_number} accepted=#{accepted} permanent=#{reply[:is_permanent]}"

    return unless accepted

    contact = channel.inbox.contact_inboxes.joins(:contact)
                     .where(contacts: { phone_number: "+#{from_number}" })
                     .first&.contact
    return unless contact

    conversation = channel.inbox.conversations.where(contact: contact).where.not(status: :resolved).last
    return unless conversation

    # Clear the permission requested flag so next call attempt goes through
    attrs = conversation.additional_attributes || {}
    attrs.delete('call_permission_requested_at')
    conversation.update!(additional_attributes: attrs)

    # Notify agents that call permission was granted
    ActionCable.server.broadcast("account_#{channel.inbox.account_id}", {
                                  event: 'whatsapp_call.permission_granted',
                                  data: {
                                    account_id: channel.inbox.account_id,
                                    conversation_id: conversation.id,
                                    contact_name: contact.name,
                                    contact_phone: contact.phone_number
                                  }
                                })
  end

  def extract_call_params(params)
    params.dig(:entry, 0, :changes, 0, :value) || {}
  end

  private

  def channel_is_inactive?(channel)
    return true if channel.blank?
    return true if channel.reauthorization_required?
    return true unless channel.account.active?

    false
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
    phone_number = "+#{wb_params[:entry].first[:changes].first.dig(:value, :metadata, :display_phone_number)}"
    phone_number_id = wb_params[:entry].first[:changes].first.dig(:value, :metadata, :phone_number_id)
    channel = Channel::Whatsapp.find_by(phone_number: phone_number)
    # validate to ensure the phone number id matches the whatsapp channel
    return channel if channel && channel.provider_config['phone_number_id'] == phone_number_id
  end
end
