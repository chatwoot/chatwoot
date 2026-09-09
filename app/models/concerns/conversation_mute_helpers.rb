module ConversationMuteHelpers
  extend ActiveSupport::Concern

  # Blocks the contact behind the conversation. When `blocked_until` is given
  # the block lifts itself once that time has passed; otherwise it is permanent.
  def mute!(blocked_until: nil)
    return unless contact

    resolved!
    contact.update(blocked: true, blocked_until: blocked_until)
    create_muted_message(blocked_until: contact.blocked_until)
  end

  def unmute!
    return unless contact

    contact.update(blocked: false, blocked_until: nil)
    create_unmuted_message
  end

  def muted?
    contact&.blocked? || false
  end
end
