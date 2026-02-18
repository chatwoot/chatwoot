class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :low

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
    case channel.provider
    when 'whatsapp_cloud'
      Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params).perform
    when 'ycloud'
      Whatsapp::IncomingMessageYcloudService.new(inbox: channel.inbox, params: params).perform
    else
      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    end
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

    # YCloud webhook payloads have a different structure
    return find_channel_from_ycloud_payload(params) if ycloud_payload?(params)

    find_channel_by_url_param(params)
  end

  def get_channel_from_wb_payload(wb_params)
    phone_number = "+#{wb_params[:entry].first[:changes].first.dig(:value, :metadata, :display_phone_number)}"
    phone_number_id = wb_params[:entry].first[:changes].first.dig(:value, :metadata, :phone_number_id)
    channel = Channel::Whatsapp.find_by(phone_number: phone_number)
    # validate to ensure the phone number id matches the whatsapp channel
    return channel if channel && channel.provider_config['phone_number_id'] == phone_number_id
  end

  def ycloud_payload?(params)
    event_type = params[:type].to_s
    # YCloud events: whatsapp.*, contact.* (CRM + unsubscribe events)
    event_type.start_with?('whatsapp.') || event_type.start_with?('contact.')
  end

  def find_channel_from_ycloud_payload(params)
    # Try to extract phone number from various YCloud event payload structures
    phone_number = extract_ycloud_phone_number(params)

    # For contact.* events, fall back to URL param since payload may not contain phone numbers
    phone_number ||= params[:phone_number] if params[:type].to_s.start_with?('contact.')

    return unless phone_number

    # YCloud phone numbers may or may not include the '+' prefix
    phone_number = "+#{phone_number}" unless phone_number.start_with?('+')
    Channel::Whatsapp.find_by(phone_number: phone_number)
  end

  def extract_ycloud_phone_number(params)
    if params[:whatsappInboundMessage].present?
      params.dig(:whatsappInboundMessage, :to)
    elsif params[:whatsappMessage].present?
      params.dig(:whatsappMessage, :from)
    elsif params[:whatsappTemplate].present?
      params[:phone_number] # Template events use URL param
    elsif params[:whatsappPhoneNumber].present?
      params.dig(:whatsappPhoneNumber, :phoneNumber)
    elsif params[:whatsappBusinessAccount].present?
      params[:phone_number] # WABA events use URL param
    elsif params[:whatsappCall].present?
      params.dig(:whatsappCall, :to) || params.dig(:whatsappCall, :from)
    elsif params[:whatsappFlow].present?
      params[:phone_number] # Flow events use URL param
    elsif params[:whatsappPayment].present?
      params[:phone_number]
    elsif params[:whatsappUserPreferences].present?
      params[:phone_number]
    else
      params[:phone_number]
    end
  end
end
