class RemoveCannedResponseOnMessages < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :messages, :canned_responses, column: :canned_response_id
  end
end
