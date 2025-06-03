class AddColumnsIsHandoverToConversation < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :is_handover, :boolean, default: false, null: false
  end
end
