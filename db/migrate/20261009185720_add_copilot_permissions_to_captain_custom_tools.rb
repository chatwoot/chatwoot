class AddCopilotPermissionsToCaptainCustomTools < ActiveRecord::Migration[7.2]
  def change
    add_column :captain_custom_tools, :copilot_permissions, :text, array: true, default: [], null: false
  end
end
