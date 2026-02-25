class AddMetaToNotifications < ActiveRecord::Migration[7.0]
  def change
    add_column :notifications, :meta, :jsonb, default: {}
  end
end
