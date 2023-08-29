class AddLockedToInstallationConfigs < ActiveRecord::Migration[6.0]
  def change
    add_column :installation_configs, :locked, :boolean, default: true, null: false
  end
end
