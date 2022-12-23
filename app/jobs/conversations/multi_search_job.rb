class Conversations::MultiSearchJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    Account.all.each do |account|
      Conversations::AccountBasedSearchJob.perform_later(account.id)
    end
  end
end
