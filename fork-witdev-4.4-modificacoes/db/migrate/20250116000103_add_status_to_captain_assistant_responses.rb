class AddStatusToCaptainAssistantResponses < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_assistant_responses, :status, :integer, default: 1, null: false
    add_index :captain_assistant_responses, :status
  end
end
