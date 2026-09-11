class AddWidgetTokenVersionToContactInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :contact_inboxes, :widget_token_version, :integer, default: 0, null: false
  end
end
