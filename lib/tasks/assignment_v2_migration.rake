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
# rubocop:disable Metrics/BlockLength
namespace :assignment_v2 do
  desc 'Migrate max_assignment_limit inbox settings to agent capacity policies'
  task migrate: :environment do
    int_max = (2**31) - 1
    policy_name = 'Auto Assignment Capacity'

    account_id = ENV.fetch('ACCOUNT_ID', nil)
    accounts = account_id.present? ? Account.where(id: account_id) : Account.all

    if account_id.blank?
      print 'No ACCOUNT_ID specified. This will migrate ALL accounts. Continue? [y/N] '
      abort 'Aborted.' unless $stdin.gets.chomp.casecmp('y').zero?
    end

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
      inboxes_with_limit = account.inboxes.where("auto_assignment_config->>'max_assignment_limit' ~ '[1-9]'")

      if inboxes_with_limit.empty?
        skipped += 1
        puts "  [#{migrated + skipped + errored}/#{total}] Account #{account.id} — skipped (no inboxes with limit)"
        next
      end

      ActiveRecord::Base.transaction do
        policy = AgentCapacityPolicy.find_or_create_by!(account: account, name: policy_name) do |p|
          p.description = 'Migrated from inbox settings'
        end

        inboxes_with_limit.each do |inbox|
          next if InboxCapacityLimit.exists?(agent_capacity_policy_id: policy.id, inbox_id: inbox.id)

          limit = [inbox.auto_assignment_config['max_assignment_limit'].to_i, int_max].min
          InboxCapacityLimit.create!(agent_capacity_policy: policy, inbox: inbox, conversation_limit: limit)
        end

        member_user_ids = InboxMember.where(inbox_id: inboxes_with_limit.select(:id)).distinct.pluck(:user_id)
        account.account_users
               .where(user_id: member_user_ids, agent_capacity_policy_id: nil)
               .find_each { |au| au.update!(agent_capacity_policy_id: policy.id) }
      end

      migrated += 1
      puts "  [#{migrated + skipped + errored}/#{total}] Account #{account.id} — migrated"
    rescue StandardError => e
      errored += 1
      puts "  [#{migrated + skipped + errored}/#{total}] Account #{account.id} — error: #{e.message}"
    end

    puts "\nDone! Migrated: #{migrated}, Skipped: #{skipped}, Errored: #{errored}, Total: #{total}"
  end
end
# rubocop:enable Metrics/BlockLength
