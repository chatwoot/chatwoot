class Whatsapp::FlowConfirmationService
  pattr_initialize [:conversation!, :payload!]

  def perform
    return if conversation.blank?
    return if outgoing_content.blank?

    conversation.messages.create!(confirmation_params)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    Rails.logger.error("[WhatsApp Flow] confirmation failed conversation=#{conversation.id}: #{e.class}: #{e.message}")
    nil
  end

  private

  def outgoing_content
    @outgoing_content ||= Whatsapp::FlowResponseFormatter.format_confirmation(payload)
  end

  def confirmation_params
    {
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :outgoing,
      content: outgoing_content,
      content_attributes: {
        whatsapp_flow_confirmation: true
      }
    }
  end
end
