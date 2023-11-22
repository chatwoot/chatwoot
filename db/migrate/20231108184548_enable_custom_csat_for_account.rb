class EnableCustomCsatForAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :csat_template_enabled, :boolean, default: false, null: false
  end
end
