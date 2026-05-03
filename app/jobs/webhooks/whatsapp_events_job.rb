class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    if template_status_update_only_event?(params)
      forward_template_status_updates(params)
      return
    end

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
    else
      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    end
  end

  private

  JUSMONITORIA_TEMPLATE_PATTERN = /\Aalerta_movimentacao_processual_v\d+\z/
  TEMPLATE_STATUS_UPDATE_FIELD = 'message_template_status_update'.freeze
  TEMPLATE_STATUS_MAP = {
    'APPROVED' => 'approved',
    'REJECTED' => 'rejected',
    'PENDING' => 'pending',
    'DISABLED' => 'disabled',
    'PAUSED' => 'paused',
    'FLAGGED' => 'flagged',
    'DELETED' => 'deleted',
    'ARCHIVED' => 'archived',
    'IN_APPEAL' => 'in_appeal',
    'LOCKED' => 'locked',
    'LIMIT_EXCEEDED' => 'limit_exceeded'
  }.freeze

  def template_status_update_only_event?(params)
    changes = whatsapp_business_changes(params)
    changes.present? && changes.all? { |change| change[:field] == TEMPLATE_STATUS_UPDATE_FIELD }
  end

  def forward_template_status_updates(params)
    whatsapp_business_entries(params).each do |entry|
      Array(entry[:changes]).each do |change|
        next unless change[:field] == TEMPLATE_STATUS_UPDATE_FIELD

        payload = build_template_status_payload(entry, change)
        next if payload.blank?

        Whatsapp::JusmonitoriaTemplateStatusForwardJob.perform_later(payload)
      end
    end
  end

  def build_template_status_payload(entry, change)
    value = (change[:value] || {}).with_indifferent_access
    template_name = value[:message_template_name].to_s
    return unless template_name.match?(JUSMONITORIA_TEMPLATE_PATTERN)

    raw_status = value[:event].presence || value[:status].presence
    {
      provider: 'meta_whatsapp',
      wabaId: entry[:id].to_s,
      event: raw_status.to_s,
      status: normalize_template_status(raw_status),
      messageTemplateId: value[:message_template_id].to_s.presence,
      messageTemplateName: template_name,
      messageTemplateLanguage: value[:message_template_language].to_s.presence,
      reason: value[:reason].presence || value[:rejection_reason].presence || value.dig(:disable_info, :reason).presence,
      raw: {
        entry: entry,
        change: change
      }
    }.compact
  end

  def normalize_template_status(raw_status)
    TEMPLATE_STATUS_MAP.fetch(raw_status.to_s.upcase, 'unknown')
  end

  def whatsapp_business_entries(params)
    return [] unless params[:object] == 'whatsapp_business_account'

    Array(params[:entry]).map { |entry| entry.with_indifferent_access }
  end

  def whatsapp_business_changes(params)
    whatsapp_business_entries(params).flat_map { |entry| Array(entry[:changes]).map(&:with_indifferent_access) }
  end

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
