namespace :onboarding do
  desc 'Reset onboarding for an account (triggers the onboarding flow again). Usage: rake onboarding:reset[account_id]'
  task :reset, [:account_id] => :environment do |_task, args|
    abort 'Error: Please provide an account ID' if args[:account_id].blank?

    account = Account.find_by(id: args[:account_id])
    abort "Error: Account with ID '#{args[:account_id]}' not found" unless account

    account.custom_attributes['onboarding_step'] = 'account_details'
    account.save!

    puts "Onboarding has been reset for account '#{account.name}' (ID: #{account.id})"
  end
end
