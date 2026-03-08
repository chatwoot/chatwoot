module Integrations::Calendly::WebhookProcessorService::NotificationHandler
  private

  def send_notification(conversation, event_type, event_details, contact, cancellation_reason: nil)
    if whatsapp_needs_template?(conversation)
      send_template_notification(conversation, event_type, event_details, contact)
    else
      send_ai_notification(conversation, event_type, event_details, contact, cancellation_reason)
    end
  rescue StandardError => e
    Rails.logger.error("Calendly: Notification failed: #{e.message}")
  end

  def send_template_notification(conversation, event_type, event_details, contact)
    template_name = @hook.settings&.dig('calendly_templates', event_type)
    if template_name.blank?
      Rails.logger.warn("Calendly: No WhatsApp template configured for '#{event_type}' — skipping notification")
      return
    end

    params = build_template_message_params(template_name, event_type, event_details, contact)
    message = Messages::MessageBuilder.new(nil, conversation, params).perform
    ::SendReplyJob.perform_later(message.id) if message&.persisted?
  end

  def build_template_message_params(template_name, event_type, event_details, contact)
    {
      content: build_booking_message(event_details, event_type == 'rescheduled'),
      message_type: :outgoing,
      private: false,
      template_params: {
        'name' => template_name, 'language' => 'en',
        'processed_params' => { 'body' => {
          '1' => contact.name.to_s.split.first || 'there',
          '2' => event_details&.dig('name') || 'Meeting',
          '3' => format_time(event_details&.dig('start_time'))
        } }
      }
    }
  end

  def send_ai_notification(conversation, event_type, event_details, contact, cancellation_reason)
    assistant = conversation.aloo_assistant
    return unless assistant&.active?

    Aloo::Current.set_from_conversation(conversation)
    content = generate_notification(event_type, event_details, contact, cancellation_reason)
    return if content.blank?

    message = create_ai_message(conversation, assistant, content)
    ::SendReplyJob.perform_later(message.id) if message&.persisted?
  ensure
    Aloo::Current.reset
  end

  def generate_notification(event_type, event_details, contact, cancellation_reason)
    result = CalendlyNotificationAgent.call(
      event_type: event_type,
      event_name: event_details&.dig('name') || 'Meeting',
      event_time: format_time(event_details&.dig('start_time')),
      contact_name: contact.name.to_s.split.first || 'there',
      cancellation_reason: cancellation_reason
    )
    result.content if result.success?
  end

  def create_ai_message(conversation, assistant, content)
    Messages::MessageBuilder.new(
      assistant, conversation,
      { content: content, message_type: :outgoing, private: false,
        content_attributes: { 'aloo_generated' => true, 'aloo_assistant_id' => assistant.id } }
    ).perform
  end

  def whatsapp_needs_template?(conversation)
    conversation.inbox&.channel_type == 'Channel::Whatsapp' && !conversation.can_reply?
  end
end
