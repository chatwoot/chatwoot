class AddSettingsToCaptainCustomTools < ActiveRecord::Migration[7.2]
  def change
    add_column :captain_custom_tools, :settings, :jsonb, default: {}, null: false
  end
end
