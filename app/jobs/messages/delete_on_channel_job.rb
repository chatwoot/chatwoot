# Revokes a message on the provider after the agent deleted it in Chatwoot.
#
# Runs async with retries because the deletion has two triggers that are mutually exclusive by
# construction (both take the message row lock): the DELETE endpoint, when the message already has a
# `source_id`, and `Whatsapp::SendOnWhatsappService`, when the message got deleted while the send was
# still in flight and the `source_id` only landed afterwards. A provider hiccup on either path would
# otherwise leave the message deleted in Chatwoot and alive on WhatsApp.
class Messages::DeleteOnChannelJob < ApplicationJob
  queue_as :high

  retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, error|
    Rails.logger.error "Failed to delete message #{job.arguments.first} on channel: #{error.message}"
  end

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return if message.blank?

    channel = message.inbox.channel
    return unless channel.respond_to?(:delete_message)
    return if message.source_id.blank?

    channel.delete_message(message, conversation: message.conversation)
  end
end
