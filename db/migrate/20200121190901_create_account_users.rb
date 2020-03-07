class CreateAccountUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :account_users do |t|
      t.references :account, foreign_key: true, index: true
      t.references :user, foreign_key: true, index: true
      t.integer :role, default: 0
      t.bigint :inviter_id
      t.timestamps
    end

    migrate_to_account_users

    remove_column :users, :account_id, :bigint
    remove_column :users, :role, :integer
    remove_column :users, :inviter_id, :bigint
  end

  def migrate_to_account_users
    ::User.find_in_batches.each do |users|
      users.each do |user|
        account_user = ::AccountUser.find_by(account_id: user.account_id, user_id: user.id, role: user.role)

        notification_setting = ::NotificationSetting.find_by(account_id: user.account_id, user_id: user.id)
        selected_email_flags = notification_setting.selected_email_flags
        notification_setting.destroy!

        next if account_user.present?

        ::AccountUser.create!(
          account_id: user.account_id,
          user_id: user.id,
          role: user[:role], # since we are overriding role method, lets fetch value from attribute
          inviter_id: user.inviter_id
        )

        updated_notification_setting = ::NotificationSetting.find_by(account_id: user.account_id, user_id: user.id)
        updated_notification_setting.selected_email_flags = selected_email_flags
        updated_notification_setting.save!
      end
    end
  end
end
