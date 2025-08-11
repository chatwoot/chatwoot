# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :assignment_v2 do
  desc 'Enable Assignment V2 for an account with default policy'
  task :enable, [:account_id] => :environment do |_task, args|
    account = Account.find(args[:account_id])

    # Create default assignment policy if not exists
    policy = account.assignment_policies.find_or_create_by!(name: 'Default Policy') do |p|
      p.description = 'Default round-robin assignment policy'
      p.assignment_order = 'round_robin'
      p.conversation_priority = 'earliest_created'
      p.enabled = true
    end

    puts "Assignment V2 enabled for account #{account.name} with policy #{policy.name}"
  end

  desc 'Disable Assignment V2 for an account'
  task :disable, [:account_id] => :environment do |_task, args|
    account = Account.find(args[:account_id])

    # Disable all assignment policies
    account.assignment_policies.find_each do |policy|
      policy.update!(enabled: false)
    end

    puts "Assignment V2 disabled for account #{account.name}"
  end

  desc 'Run assignment for all enabled inboxes'
  task run_all: :environment do
    count = 0

    Inbox.joins(:assignment_policy)
         .where(assignment_policies: { enabled: true })
         .find_each do |inbox|
      AssignmentV2::AssignmentJob.perform_later(inbox_id: inbox.id)
      count += 1
    end

    puts "Queued assignment jobs for #{count} inboxes"
  end

  desc 'Show Assignment V2 status'
  task status: :environment do
    puts 'Assignment V2 Status'
    puts '==================='

    total_policies = AssignmentPolicy.count
    enabled_policies = AssignmentPolicy.enabled.count

    puts "Total Assignment Policies: #{total_policies}"
    puts "Enabled Policies: #{enabled_policies}"
    puts

    inboxes_with_v2 = Inbox.joins(:assignment_policy).count
    total_inboxes = Inbox.count

    puts "Total Inboxes: #{total_inboxes}"
    puts "Inboxes with Assignment V2: #{inboxes_with_v2}"
  end
end
# rubocop:enable Metrics/BlockLength
