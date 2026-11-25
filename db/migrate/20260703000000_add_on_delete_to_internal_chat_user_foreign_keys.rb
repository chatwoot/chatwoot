class AddOnDeleteToInternalChatUserForeignKeys < ActiveRecord::Migration[7.1]
  def up
    # Channels keep their history when the creator is deleted: just clear created_by.
    remove_foreign_key :internal_chat_channels, column: :created_by_id
    add_foreign_key :internal_chat_channels, :users, column: :created_by_id, on_delete: :nullify

    # Drafts are personal and ephemeral: drop them with their owner.
    remove_foreign_key :internal_chat_drafts, :users
    add_foreign_key :internal_chat_drafts, :users, on_delete: :cascade
  end

  def down
    remove_foreign_key :internal_chat_channels, column: :created_by_id
    add_foreign_key :internal_chat_channels, :users, column: :created_by_id

    remove_foreign_key :internal_chat_drafts, :users
    add_foreign_key :internal_chat_drafts, :users
  end
end
