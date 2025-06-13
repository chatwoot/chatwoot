class AddAutoReplyPostCommentsFeatureToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :auto_reply_post_comments_enabled, :boolean, default: false
    add_column :inboxes, :auto_reply_post_comments_message, :string
  end
end
