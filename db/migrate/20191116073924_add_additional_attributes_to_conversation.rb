class AddAdditionalAttributesToConversation < ActiveRecord::Migration[6.0]
  def change
    add_column :conversations, :additional_attributes, :jsonb
  end
end
