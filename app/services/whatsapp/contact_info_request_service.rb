class Whatsapp::ContactInfoRequestService
  pattr_initialize [:conversation!, :sender!]

  def perform
    conversation.with_lock do
      Whatsapp::ContactInfoRequestEligibilityService.new(conversation: conversation).ensure_available!

      Messages::MessageBuilder.new(sender, conversation, message_params).perform
    end
  end

  private

  def message_params
    {
      content: I18n.t('conversations.messages.whatsapp.request_contact_info'),
      content_attributes: {
        whatsapp_contact_info: {
          type: 'request',
          state: 'pending'
        }
      }
    }
  end
end
