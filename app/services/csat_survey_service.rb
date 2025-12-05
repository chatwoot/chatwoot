class CsatSurveyService
  pattr_initialize [:conversation!]

  def perform
    return unless should_send_csat_survey?

    if whatsapp_channel? && template_available_and_approved?
      send_whatsapp_template_survey
    elsif within_messaging_window?
      ::MessageTemplates::Template::CsatSurvey.new(conversation: conversation).perform
    else
      create_csat_not_sent_activity_message
    end
  end

  private

  delegate :inbox, :contact, to: :conversation

  def should_send_csat_survey?
    conversation_allows_csat? && csat_enabled? && !csat_already_sent?
  end

  def conversation_allows_csat?
    conversation.resolved? && !conversation.tweet?
  end

  def csat_enabled?
    inbox.csat_survey_enabled?
  end

  def csat_already_sent?
    conversation.messages.where(content_type: :input_csat).present?
  end

  def within_messaging_window?
    conversation.can_reply?
  end

  def whatsapp_channel?
    inbox.channel_type == 'Channel::Whatsapp'
  end

  def template_available_and_approved?
    template_config = inbox.csat_config&.dig('template')
    return false unless template_config

    template_name = template_config['name'] || Whatsapp::CsatTemplateNameService.csat_template_name(inbox.id)
    status_result = inbox.channel.provider_service.get_template_status(template_name)

    status_result[:success] && status_result[:template][:status] == 'APPROVED'
  rescue StandardError => e
    Rails.logger.error "Error checking CSAT template status: #{e.message}"
    false
  end

  def send_whatsapp_template_survey
    template_config = inbox.csat_config&.dig('template')
    template_name = template_config['name'] || Whatsapp::CsatTemplateNameService.csat_template_name(inbox.id)

    phone_number = conversation.contact_inbox.source_id
    template_info = build_template_info(template_name, template_config)
    message = build_csat_message

    message_id = inbox.channel.provider_service.send_template(phone_number, template_info, message)

    message.update!(source_id: message_id) if message_id.present?
  rescue StandardError => e
    Rails.logger.error "Error sending WhatsApp CSAT template for conversation #{conversation.id}: #{e.message}"
  end

  def build_template_info(template_name, template_config)
    {
      name: template_name,
      lang_code: template_config['language'] || 'en',
      parameters: [
        {
          type: 'button',
          sub_type: 'url',
          index: '0',
          parameters: [{ type: 'text', text: conversation.uuid }]
        }
      ]
    }
  end

  def build_csat_message
    conversation.messages.build(
      account: conversation.account,
      inbox: inbox,
      message_type: :outgoing,
      content: inbox.csat_config&.dig('message') || 'Please rate this conversation',
      content_type: :input_csat
    )
  end

  def create_csat_not_sent_activity_message
    content = I18n.t('conversations.activity.csat.not_sent_due_to_messaging_window')
    activity_message_params = {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content
    }
    ::Conversations::ActivityMessageJob.perform_later(conversation, activity_message_params) if content
  end
end
