class Internal::SeedAccountJob < ApplicationJob
  queue_as :low

  def perform(account)
    Seeders::AccountSeeder.new(account: account).perform!
  end
end
