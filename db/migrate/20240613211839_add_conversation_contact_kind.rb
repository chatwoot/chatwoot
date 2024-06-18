class AddConversationContactKind < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :contact_kind, :integer, default: 0
  end
end
