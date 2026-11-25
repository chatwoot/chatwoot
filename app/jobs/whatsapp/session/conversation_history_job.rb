# One conversation asking the phone for what came before it.
#
# A job rather than an inline call because `request_history` is an HTTP round trip to the
# provider, and the operator pressing the control should not wait on it: the answer arrives
# on the webhook minutes later regardless, so there is nothing for the request to return.
class Whatsapp::Session::ConversationHistoryJob < ApplicationJob
  queue_as :low

  def perform(conversation)
    channel = conversation.inbox.channel
    return unless channel.try(:session_capabilities)&.include?('history_sync')

    contact = conversation.contact
    return if contact.blank?

    channel.provider_service.request_history(contact)
  rescue Whatsapp::Session::Errors::Error => e
    Rails.logger.warn(
      "[WHATSAPP SESSION] history request failed for conversation ##{conversation.display_id}: #{e.message}"
    )
  end
end
