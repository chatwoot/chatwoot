class AddChannelAttributesToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :channel_attributes, :jsonb, default: {}
  end
end
