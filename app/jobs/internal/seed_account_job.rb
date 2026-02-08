class Internal::SeedAccountJob < ApplicationJob
  queue_as :low

  def perform(account)
    # Reload account to ensure we have fresh data
    account.reload

    # Perform seeding
    Seeders::AccountSeeder.new(account: account).perform!

    # Reload again after seeding to ensure cache is fresh
    account.reload

    Rails.logger.info("Account seeding completed successfully for account_id: #{account.id}")
  rescue StandardError => e
    Rails.logger.error("Account seeding failed for account_id: #{account.id} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
