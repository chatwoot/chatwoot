class AddAssistantToCaptainCustomTools < ActiveRecord::Migration[7.2]
  def change
    add_column :captain_custom_tools, :assistant_id, :bigint
    add_index :captain_custom_tools, [:assistant_id, :slug], unique: true
    remove_index :captain_custom_tools, [:account_id, :slug], unique: true
  end
end
