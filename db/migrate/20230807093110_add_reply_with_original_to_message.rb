class AddReplyWithOriginalToMessage < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :enable_reply_with_original_message, :boolean, default: false
  end
end
