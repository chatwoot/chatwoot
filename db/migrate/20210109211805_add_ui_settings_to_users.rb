class AddUiSettingsToUsers < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :ui_settings, :jsonb, default: {}
  end

  def down
    remove_column :users, :ui_settings, :jsonb
  end
end
