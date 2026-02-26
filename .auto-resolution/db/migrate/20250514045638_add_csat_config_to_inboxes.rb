class AddCsatConfigToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :csat_config, :jsonb, default: {}, null: false
  end
end
