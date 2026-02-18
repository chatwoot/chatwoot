# frozen_string_literal: true

namespace :crm do
  desc 'Sync agents with CRM users for all accounts with active CRM integrations'
  task sync_agents: :environment do
    puts 'Starting agent sync with CRM...'

    Crm::AgentSyncJob.perform_now

    puts 'Agent sync completed!'
  end

  desc 'Sync agents with CRM users for a specific account'
  task :sync_agents_for_account, [:account_id] => :environment do |_t, args|
    account_id = args[:account_id]

    unless account_id
      puts 'Error: Please provide an account_id'
      puts 'Usage: rails crm:sync_agents_for_account[ACCOUNT_ID]'
      exit 1
    end

    account = Account.find(account_id)
    hook = account.hooks.crm_hooks.enabled.first

    unless hook
      puts "Error: No active CRM integration found for account #{account_id}"
      exit 1
    end

    puts "Syncing agents for account #{account_id} with CRM #{hook.app_id}..."

    service = case hook.app_id
              when 'zoho'
                Crm::Zoho::AgentSyncService.new(account)
              else
                puts "Error: Unsupported CRM provider: #{hook.app_id}"
                exit 1
              end

    result = service.sync

    if result[:success]
      puts "\n✓ Sync completed successfully!"
      puts "  - Synced: #{result[:synced_count]}"
      puts "  - Failed: #{result[:failed_count]}"

      if result[:errors].any?
        puts "\nErrors:"
        result[:errors].each { |error| puts "  - #{error}" }
      end
    else
      puts "\n✗ Sync failed: #{result[:error]}"
    end
  end

  desc 'Show CRM sync status for an account'
  task :sync_status, [:account_id] => :environment do |_t, args|
    account_id = args[:account_id]

    unless account_id
      puts 'Error: Please provide an account_id'
      puts 'Usage: rails crm:sync_status[ACCOUNT_ID]'
      exit 1
    end

    account = Account.find(account_id)
    hook = account.hooks.crm_hooks.enabled.first

    unless hook
      puts "No active CRM integration found for account #{account_id}"
      exit 0
    end

    puts "\nCRM Integration Status for Account #{account_id}"
    puts "=" * 60
    puts "CRM Provider: #{hook.app_id}"
    puts "Status: #{hook.status}"
    puts "\nAgent Sync Status:"
    puts "-" * 60

    account.account_users.includes(:user).each do |account_user|
      user = account_user.user
      status = if account_user.crm_synced?
                 role_info = account_user.crm_role.present? ? ", Role: #{account_user.crm_role}" : ''
                 "✓ Synced (ID: #{account_user.crm_external_id}#{role_info}, Last: #{account_user.crm_synced_at&.strftime('%Y-%m-%d %H:%M')})"
               else
                 '✗ Not synced'
               end

      puts "#{user.email.ljust(40)} #{status}"
    end

    puts "\nSummary:"
    synced = account.account_users.where.not(crm_external_id: nil).count
    total = account.account_users.count
    puts "Synced: #{synced}/#{total} agents"
  end
end
