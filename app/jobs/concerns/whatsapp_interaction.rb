# frozen_string_literal: true

# WhatsApp interaction helpers for AI agent replies:
# typing indicators, reactions, natural delay simulation.
module WhatsappInteraction
  extend ActiveSupport::Concern

  private

  def whatsapp_channel?(conversation)
    conversation.inbox&.channel_type == 'Channel::Whatsapp' &&
      conversation.inbox&.channel&.provider == 'whatsapp_cloud'
  end

  def contact_phone(conversation)
    conversation.contact&.phone_number&.delete('+')
  end

  def send_whatsapp_typing(message)
    return unless whatsapp_channel?(message.conversation)
    return if message.source_id.blank?

    channel = message.conversation.inbox.channel
    result = channel.send_typing_indicator(message.source_id)
    Rails.logger.info "[AI_AGENT] Typing indicator sent for message #{message.id} (source_id=#{message.source_id}): #{result}"
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] WhatsApp typing indicator failed: #{e.class} — #{e.message}"
  end

  # Calculates and applies a natural typing delay based on reply length.
  # Re-sends the typing indicator right before the delay so the user
  # still sees "digitando..." even if the LLM call took > 25s.
  def simulate_typing_delay(message, reply_text)
    return unless whatsapp_channel?(message.conversation)
    return if reply_text.blank?

    delay = [TYPING_DELAY_MIN + (reply_text.length * TYPING_DELAY_PER_CHAR), TYPING_DELAY_MAX].min
    Rails.logger.info "[AI_AGENT] Typing delay: #{delay.round(1)}s for #{reply_text.length} chars"
    send_whatsapp_typing(message)
    sleep(delay)
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] Typing delay failed: #{e.message}"
  end

  def send_whatsapp_reaction(message, emoji)
    return unless whatsapp_channel?(message.conversation)

    channel = message.conversation.inbox.channel
    phone = contact_phone(message.conversation)
    return if phone.blank? || message.source_id.blank?

    channel.send_reaction(phone, message.source_id, emoji)
  rescue StandardError => e
    Rails.logger.warn "[AI_AGENT] WhatsApp reaction failed: #{e.message}"
  end

  # Extracts optional [REACT:emoji] prefix from the LLM reply.
  # Returns [clean_reply, emoji_or_nil].
  def extract_reaction(reply)
    return [reply, nil] if reply.blank?

    match = reply.match(REACTION_PATTERN)
    return [reply, nil] unless match

    emoji = match[1].strip
    clean_reply = reply.sub(REACTION_PATTERN, '').strip
    [clean_reply, emoji]
  end
end
