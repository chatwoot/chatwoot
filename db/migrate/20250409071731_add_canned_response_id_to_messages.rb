class AddCannedResponseIdToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :canned_response_id, :integer
    add_index :messages, :canned_response_id
    add_foreign_key :messages, :canned_responses, column: :canned_response_id, on_delete: :nullify
  end
end
