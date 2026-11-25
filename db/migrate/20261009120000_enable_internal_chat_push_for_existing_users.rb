class EnableInternalChatPushForExistingUsers < ActiveRecord::Migration[7.1]
  # push_flags bits for internal_chat_mention (9) and internal_chat_new_message (10).
  INTERNAL_CHAT_PUSH_BITS = 256 | 512

  # New account users get both flags by default. Rows with either flag already set belong to
  # someone who opened the preferences after internal chat notifications shipped, and rows with
  # no push flag at all belong to someone who turned push off (every setting has been created
  # with conversation-assignment push since 2020), so both keep their choice.
  def up
    execute(<<~SQL.squish)
      UPDATE notification_settings
      SET push_flags = push_flags | #{INTERNAL_CHAT_PUSH_BITS}
      WHERE push_flags & #{INTERNAL_CHAT_PUSH_BITS} = 0
        AND push_flags <> 0
    SQL
  end

  def down; end
end
