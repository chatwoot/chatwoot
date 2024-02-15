class AddMetaAndDescriptionToNotifications < ActiveRecord::Migration[7.0]
  def change
    add_column :notifications, :meta, :jsonb, default: {}
    add_column :notifications, :description, :text, default: ''
  end
end
