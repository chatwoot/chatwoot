class AddNotificationSettings < ActiveRecord::Migration[6.0]
  def change
    return if ActiveRecord::Base.connection.data_source_exists? 'notification_settings'

    create_table :notification_settings do |t|
      t.integer :account_id
      t.integer :user_id
      t.integer :email_flags, null: false, default: 0

      t.timestamps
    end

    add_index :notification_settings, [:account_id, :user_id], unique: true, name: 'by_account_user'

    ::User.find_in_batches do |users_batch|
      users_batch.each do |user|
        user_notification_setting = user.notification_settings.new(account_id: user.account_id)
        user_notification_setting.conversation_creation = false
        user_notification_setting.conversation_assignment = true
        user_notification_setting.save!
      end
    end
  end
end
