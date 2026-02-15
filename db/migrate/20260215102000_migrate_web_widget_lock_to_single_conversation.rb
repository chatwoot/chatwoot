# frozen_string_literal: true

class MigrateWebWidgetLockToSingleConversation < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      UPDATE inboxes
      SET lock_to_single_conversation = NOT allow_messages_after_resolved
      WHERE channel_type = 'Channel::WebWidget'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE inboxes
      SET allow_messages_after_resolved = NOT lock_to_single_conversation
      WHERE channel_type = 'Channel::WebWidget'
    SQL
  end
end
