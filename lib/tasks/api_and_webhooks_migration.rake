# Grandfather api_and_webhooks for existing accounts (cloud only).
#
# Adds api_and_webhooks to each account's manually_managed_features internal
# attribute so per-account billing reconciles never strip the feature from
# accounts that existed before the flag was introduced. Idempotent.
#
# Usage Examples:
#   # Grandfather a single account
#   ACCOUNT_ID=1 bundle exec rake api_and_webhooks:grandfather
#
#   # Grandfather all accounts in the installation
#   bundle exec rake api_and_webhooks:grandfather
# rubocop:disable Metrics/BlockLength
namespace :api_and_webhooks do
  desc 'Grandfather api_and_webhooks via manually_managed_features for existing accounts'
  task grandfather: :environment do
    abort 'Aborted. This task requires the enterprise edition.' unless ChatwootApp.enterprise?

    account_id = ENV.fetch('ACCOUNT_ID', nil)
    accounts = account_id.present? ? Account.where(id: account_id) : Account.all

    if account_id.blank?
      print 'No ACCOUNT_ID specified. This will grandfather ALL accounts. Continue? [y/N] '
      abort 'Aborted.' unless $stdin.gets.chomp.casecmp('y').zero?
    end

    if account_id.present? && accounts.empty?
      puts "Error: Account with ID #{account_id} not found"
      exit(1)
    end

    total = accounts.count
    puts "Grandfathering api_and_webhooks for #{total} account(s)..."

    updated = 0
    skipped = 0
    errored = 0

    accounts.find_each do |account|
      service = Internal::Accounts::InternalAttributesService.new(account)
      features = service.manually_managed_features

      if features.include?('api_and_webhooks')
        skipped += 1
        next
      end

      service.manually_managed_features = features + ['api_and_webhooks']
      account.enable_features!('api_and_webhooks')
      updated += 1
    rescue StandardError => e
      errored += 1
      puts "  Account #{account.id} — error: #{e.message}"
    end

    puts "Done! Updated: #{updated}, Skipped: #{skipped}, Errored: #{errored}, Total: #{total}"
  end
end
# rubocop:enable Metrics/BlockLength
