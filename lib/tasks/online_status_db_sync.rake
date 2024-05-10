# This will sync user_availability from database to redis for all users



namespace :online_status_sync do
  desc 'Sync user_availability from database to redis for all Account Users'
  task all: :environment do
    AccountUser.find_each do |user|
      puts "Syncing user #{user.user_id} from account #{user.account_id} with status #{user.availability}"
      OnlineStatusTracker.set_status(user.account_id, user.user_id, user.availability)
    end
  end
end

