class AddColumnsToCampaign < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :private_note, :text, null: true
    add_column :campaigns, :flexible_scheduled_at, :jsonb, null: true
    add_column :campaigns, :inboxes, :jsonb, null: true
    change_column_null :campaigns, :inbox_id, true
    change_column_null :campaigns, :message, true
    change_column_null :campaigns, :scheduled_at, true
  end
end
