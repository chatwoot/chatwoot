# frozen_string_literal: true

# Run with:
#   bundle exec rake chatwoot:ops:purge_inactive_accounts
#   bundle exec rake chatwoot:ops:purge_inactive_accounts:dry_run

namespace :chatwoot do
  namespace :ops do
    desc 'Identify and mark inactive accounts for deletion'
    task purge_inactive_accounts: :environment do
      puts 'Starting inactive account purge...'
      
      inactive_accounts = Internal::InactiveAccountIdentificationService.inactive_accounts
      
      if inactive_accounts.empty?
        puts 'No inactive accounts found.'
        next
      end

      puts "Found #{inactive_accounts.count} inactive accounts:"
      inactive_accounts.each do |account|
        puts "  - Account ID: #{account.id}, Name: #{account.name}, Created: #{account.created_at}"
      end

      print 'Do you want to mark these accounts for deletion? (y/N): '
      confirm = $stdin.gets.strip.downcase
      
      if %w[y yes].include?(confirm)
        marked_count = 0
        inactive_accounts.each do |account|
          if account.mark_for_deletion('Account Inactive')
            puts "✓ Marked account #{account.id} (#{account.name}) for deletion"
            marked_count += 1
          else
            puts "✗ Failed to mark account #{account.id} for deletion: #{account.errors.full_messages.join(', ')}"
          end
        end
        puts "Successfully marked #{marked_count} out of #{inactive_accounts.count} accounts for deletion."
      else
        puts 'Operation cancelled.'
      end
    end

    desc 'Show inactive accounts without marking them for deletion (dry run)'
    task 'purge_inactive_accounts:dry_run' => :environment do
      puts 'Dry run: Identifying inactive accounts...'
      
      inactive_accounts = Internal::InactiveAccountIdentificationService.inactive_accounts
      
      if inactive_accounts.empty?
        puts 'No inactive accounts found.'
        next
      end

      puts "Found #{inactive_accounts.count} inactive accounts:"
      inactive_accounts.each do |account|
        last_user_activity = account.account_users.maximum(:active_at)
        last_conversation = account.conversations.maximum(:updated_at)
        
        puts "  - Account ID: #{account.id}"
        puts "    Name: #{account.name}"
        puts "    Created: #{account.created_at}"
        puts "    Last user activity: #{last_user_activity || 'Never'}"
        puts "    Last conversation: #{last_conversation || 'None'}"
        puts "    Users count: #{account.users.count}"
        puts "    Conversations count: #{account.conversations.count}"
        puts "    Status: #{account.status}"
        puts ""
      end

      puts "Total: #{inactive_accounts.count} inactive accounts identified."
      puts "Run 'bundle exec rake chatwoot:ops:purge_inactive_accounts' to mark them for deletion."
    end
  end
end