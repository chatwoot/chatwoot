# frozen_string_literal: true

# Sends a typing indicator ("digitando...") to the WhatsApp contact.
# Fire-and-forget — the indicator auto-dismisses after 25 seconds
# or when the agent sends a reply.
class Whatsapp::SendTypingIndicatorJob < ApplicationJob
  queue_as :low

  def perform(channel, message_source_id)
    return unless channel.is_a?(Channel::Whatsapp)

    channel.send_typing_indicator(message_source_id)
  end
end
