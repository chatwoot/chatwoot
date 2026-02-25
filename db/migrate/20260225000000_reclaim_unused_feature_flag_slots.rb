class ReclaimUnusedFeatureFlagSlots < ActiveRecord::Migration[7.0]
  # Maps slot position (1-indexed) to the flag name being retired.
  # Bit mask for a slot at position N is 1 << (N - 1), matching FlagShihTzu's encoding.
  RETIRED_SLOTS = {
    20 => 'mobile_v2',
    29 => 'response_bot',
    30 => 'message_reply_to',
    31 => 'insert_article_in_reply',
    39 => 'report_v4',
    48 => 'whatsapp_embedded_signup',
    52 => 'twilio_content_templates'
  }.freeze

  def up
    mask = RETIRED_SLOTS.keys.sum { |pos| 1 << (pos - 1) }

    execute(<<~SQL.squish)
      UPDATE accounts
      SET feature_flags = feature_flags & ~(#{mask}::bigint)
      WHERE (feature_flags & #{mask}::bigint) != 0
    SQL
  end
end
