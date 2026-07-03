class AddCascadeToCrmCardConversationsConversationFk < ActiveRecord::Migration[7.0]
  def up
    remove_foreign_key :crm_card_conversations, :conversations
    add_foreign_key :crm_card_conversations, :conversations, on_delete: :cascade
  end

  def down
    remove_foreign_key :crm_card_conversations, :conversations
    add_foreign_key :crm_card_conversations, :conversations
  end
end
