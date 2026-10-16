class AddEditedToCaptainAssistantResponses < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_assistant_responses, :edited, :boolean, default: false, null: false
  end
end
