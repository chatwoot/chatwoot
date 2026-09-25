class Internal::SeedAccountJob < ApplicationJob
  queue_as :within_10_minutes

  def perform(account)
    Seeders::AccountSeeder.new(account: account).perform!
  end
end
