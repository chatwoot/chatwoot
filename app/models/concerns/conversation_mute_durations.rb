# Preset durations accepted by the conversation mute endpoint and the
# `mute_conversation` automation action.
module ConversationMuteDurations
  PRESETS = {
    '1_hour' => 1.hour,
    '8_hours' => 8.hours,
    '1_day' => 1.day,
    '7_days' => 7.days
  }.freeze

  # Preset key -> absolute time. Unknown keys (including 'permanent') -> nil.
  def self.resolve(value)
    key = value.to_s
    return if key.blank?

    Time.current + PRESETS[key] if PRESETS.key?(key)
  end

  # Accepts a preset key or an ISO8601 timestamp. Anything else (blank,
  # unknown, in the past, unparsable) yields nil, i.e. a permanent block,
  # which is the previous behaviour of the endpoint.
  def self.parse(value)
    raw = value.to_s
    return if raw.blank?
    return resolve(raw) if PRESETS.key?(raw)

    parsed = Time.zone.parse(raw)
    parsed if parsed&.future?
  rescue ArgumentError
    nil
  end
end
