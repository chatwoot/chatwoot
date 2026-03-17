# Migrate max_assignment_limit to Agent Capacity Policies
#
# Converts legacy per-inbox max_assignment_limit settings into
# AgentCapacityPolicy records used by Assignment V2.
#
# Usage Examples:
#   # Migrate a single account
#   ACCOUNT_ID=1 bundle exec rake assignment_v2:migrate
#
#   # Migrate all accounts in the installation
#   bundle exec rake assignment_v2:migrate
#
# Parameters:
#   ACCOUNT_ID: (optional) ID of the account to migrate. If omitted, migrates all accounts.
#
namespace :assignment_v2 do
  desc 'Migrate max_assignment_limit inbox settings to agent capacity policies'
  task migrate: :environment do
    require 'migration/account_assignment_policy_job'

    account_id = ENV.fetch('ACCOUNT_ID', nil)
    accounts = account_id.present? ? Account.where(id: account_id) : Account.all

    if account_id.present? && accounts.empty?
      puts "Error: Account with ID #{account_id} not found"
      exit(1)
    end

    total = accounts.count
    puts "Migrating assignment policies for #{total} account(s)..."
    puts "Started at: #{Time.current}"

    migrated = 0
    skipped = 0
    errored = 0

    accounts.find_each do |account|
      Migration::AccountAssignmentPolicyJob.perform_now(account)
      migrated += 1
      puts "  [#{migrated + skipped + errored}/#{total}] Account #{account.id} — migrated"
    rescue StandardError => e
      errored += 1
      puts "  [#{migrated + skipped + errored}/#{total}] Account #{account.id} — error: #{e.message}"
    end

    puts "\nDone! Migrated: #{migrated}, Errored: #{errored}, Total: #{total}"
  end
end
