class AddAllowedCustomMessageUserIdsToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :allowed_custom_message_user_ids, :integer, array: true, default: []
  end
end
