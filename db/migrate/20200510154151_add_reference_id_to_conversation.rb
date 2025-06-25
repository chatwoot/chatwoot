class AddReferenceIdToConversation < ActiveRecord::Migration[6.0]
  def change
    add_column :conversations, :reference_id, :string
  end
end
