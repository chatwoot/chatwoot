class AddOnlineStatusToAccountUsers < ActiveRecord::Migration[6.1]
  def change
    change_table :account_users, bulk: true do |t|
      t.integer :availability, default: 0, null: false
      t.boolean :auto_offline, default: true, null: false
    end
  end

  # run as a seperate data migration if you want to migrate the user statuses
  def update_existing_user_availability
    User.find_in_batches do |user_batch|
      user_batch.each do |user|
        availability = user.availability
        user.account_users.update(availability: availability)
      end
    end
  end
end
