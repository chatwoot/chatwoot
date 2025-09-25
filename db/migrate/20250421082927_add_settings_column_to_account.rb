class AddSettingsColumnToAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :settings, :jsonb, default: {}
  end
end
