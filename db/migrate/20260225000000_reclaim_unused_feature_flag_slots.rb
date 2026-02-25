class ReclaimUnusedFeatureFlagSlots < ActiveRecord::Migration[7.0]
  # Bit positions (1-indexed) of the retired flags, snapshotted at the time this
  # migration was written. Using hardcoded positions + raw SQL so this migration
  # remains deterministic regardless of future renames in config/features.yml.
  # Bit mask for position N = 1 << (N - 1), matching FlagShihTzu's encoding.
  #
  # pos 20 => mobile_v2
  # pos 29 => response_bot
  # pos 30 => message_reply_to
  # pos 31 => insert_article_in_reply
  # pos 39 => report_v4
  # pos 48 => whatsapp_embedded_signup
  # pos 52 => twilio_content_templates
  RETIRED_FLAGS_MASK = (
    (1 << 19) |
    (1 << 28) |
    (1 << 29) |
    (1 << 30) |
    (1 << 38) |
    (1 << 47) |
    (1 << 51)
  ).freeze

  def up
    execute(<<~SQL.squish)
      UPDATE accounts
      SET feature_flags = feature_flags & ~(#{RETIRED_FLAGS_MASK}::bigint)
      WHERE (feature_flags & #{RETIRED_FLAGS_MASK}::bigint) != 0
    SQL
  end
end
