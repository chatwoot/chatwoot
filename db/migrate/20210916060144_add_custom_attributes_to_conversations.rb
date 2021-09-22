class AddCustomAttributesToConversations < ActiveRecord::Migration[6.1]
  def change
    add_column :conversations, :custom_attributes, :jsonb, default: {}
  end
end
