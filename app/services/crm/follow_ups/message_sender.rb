class Crm::FollowUps::MessageSender
  Result = Struct.new(:status, :message, :error, keyword_init: true) do
    def self.sent(message)
      new(status: :sent, message: message)
    end

    def self.failed(error)
      new(status: :failed, error: error)
    end

    def self.skipped
      new(status: :skipped)
    end
  end

  def initialize(follow_up:)
    @follow_up = follow_up
  end

  def perform
    return Result.skipped unless deliverable?
    return delivery_failure('conversation_required') if @follow_up.conversation.blank?
    return delivery_failure('not_whatsapp_capable') unless whatsapp_window.whatsapp_capable?
    return delivery_failure('sender_required') if sender.blank?

    message = deliver_message!
    persist_sent_message!(message)
    Result.sent(message)
  rescue StandardError => e
    Result.failed(e.message)
  end

  def deliverable?
    @follow_up.auto_send_message? && sent_message_id.blank?
  end

  def deliver_message!
    conversation = @follow_up.conversation
    return create_session_message(conversation, sender) if whatsapp_window.can_send_session_message?

    create_template_message(conversation, sender)
  end

  def delivery_failure(error)
    Result.failed(error)
  end

  def sender
    @sender ||= @follow_up.created_by || @follow_up.assignee
  end

  def whatsapp_window
    @whatsapp_window ||= Crm::FollowUps::MessagingWindow.new(@follow_up.conversation)
  end

  private

  def create_session_message(conversation, sender)
    Messages::MessageBuilder.new(
      sender,
      conversation,
      ActionController::Parameters.new(
        content: metadata['message_body'].to_s.strip,
        private: false,
        content_attributes: { crm_follow_up_id: @follow_up.id }
      )
    ).perform
  end

  def create_template_message(conversation, sender)
    inbox = conversation.inbox
    if inbox.channel_type == 'Channel::Api'
      create_api_template_message(conversation, sender)
    else
      create_native_template_message(conversation, sender)
    end
  end

  def create_api_template_message(conversation, sender)
    template = load_api_template!(conversation)
    contact = conversation.contact
    rendered_body = WhatsappApiCampaigns::TemplateRenderer.new(
      template: template.body,
      contact: contact,
      variables: template_variables
    ).render

    Messages::MessageBuilder.new(
      sender,
      conversation,
      ActionController::Parameters.new(
        content: rendered_body,
        private: false,
        content_attributes: {
          crm_follow_up_id: @follow_up.id,
          crm_follow_up_template_id: template.id,
          crm_follow_up_send_mode: 'template'
        }
      )
    ).perform
  end

  def create_native_template_message(conversation, sender)
    Messages::MessageBuilder.new(
      sender,
      conversation,
      ActionController::Parameters.new(
        content: metadata['message_body'].to_s.strip.presence,
        private: false,
        template_params: native_template_params,
        content_attributes: {
          crm_follow_up_id: @follow_up.id,
          crm_follow_up_send_mode: 'template'
        }
      )
    ).perform
  end

  def load_api_template!(conversation)
    template_id = metadata['whatsapp_api_message_template_id'].presence
    raise 'whatsapp_api_message_template_id is required outside the messaging window' if template_id.blank?

    template = @follow_up.account.whatsapp_api_message_templates.active.find_by(id: template_id, inbox_id: conversation.inbox_id)
    raise 'whatsapp_api_message_template is invalid for this conversation inbox' if template.blank?

    template
  end

  def native_template_params
    {
      name: metadata['template_name'].to_s.strip,
      namespace: metadata['template_namespace'].to_s.strip.presence,
      language: metadata['template_language'].to_s.strip,
      processed_params: template_variables
    }
  end

  # Slot values composed by the AI follow-up composer (keys "1", "2", …). On the
  # native WhatsApp path these become the template's positional processed_params;
  # on the Channel::Api path they feed TemplateRenderer's named-variable lookup
  # (TemplateRenderer still ignores anything it does not support). Returns {} for
  # plain auto-send follow-ups that carry no template variables.
  def template_variables
    metadata['template_processed_params'].presence&.to_h || {}
  end

  def persist_sent_message!(message)
    updated_metadata = metadata.merge(
      'sent_message_id' => message.id,
      'sent_at' => Time.current.iso8601,
      'send_mode' => message.content_attributes.to_h['crm_follow_up_send_mode'] || 'session'
    )
    @follow_up.update!(metadata: updated_metadata)
  end

  def sent_message_id
    metadata['sent_message_id']
  end

  def metadata
    @metadata ||= (@follow_up.metadata || {}).to_h.stringify_keys
  end
end
