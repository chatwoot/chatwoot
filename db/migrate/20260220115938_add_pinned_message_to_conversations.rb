# frozen_string_literal: true

class AddPinnedMessageToConversations < ActiveRecord::Migration[7.1]
  def change
    add_reference :conversations, :pinned_message, foreign_key: { to_table: :messages, on_delete: :nullify }, index: true
  end
end
