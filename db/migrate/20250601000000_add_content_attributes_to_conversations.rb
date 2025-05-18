class AddContentAttributesToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :content_attributes, :jsonb, default: {}, null: false
  end
end 