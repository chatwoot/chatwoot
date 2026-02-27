module ConversationMuteHelpers
  extend ActiveSupport::Concern

  BAN_DURATIONS = {
    '1_hour'  => 1.hour,
    '8_hours' => 8.hours,
    '1_day'   => 1.day,
    '7_days'  => 7.days,
  }.freeze

  def mute!(banned_until: nil)
    return unless contact

    resolved!
    contact.update!(blocked: true, blocked_until: parse_banned_until(banned_until))
    create_muted_message
  end

  def unmute!
    return unless contact

    contact.update!(blocked: false, blocked_until: nil)
    create_unmuted_message
  end

  def muted?
    return false unless contact&.blocked?

    if contact.blocked_until.present? && contact.blocked_until < Time.current
      unmute!
      return false
    end

    true
  end

  private

  def parse_banned_until(raw)
    return nil if raw.blank?

    if BAN_DURATIONS.key?(raw.to_s)
      Time.current + BAN_DURATIONS[raw.to_s]
    else
      Time.zone.parse(raw.to_s)
    end
  rescue ArgumentError, TypeError
    nil
  end
end
