module ConversationMuteHelpers
  extend ActiveSupport::Concern

  def mute!
    return unless contact

    resolved!
    contact.update!(blocked: true)
    create_muted_message
  end

  def unmute!
    return unless contact

    contact.update!(blocked: false)
    create_unmuted_message
  end

  def muted?
    contact&.blocked? || false
  end
end
