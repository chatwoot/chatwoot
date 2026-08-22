class Migration::BackfillCompaniesContactsCountJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    return unless false

    Company.find_in_batches(batch_size: 100) do |company_batch|
      company_batch.each do |company|
        Company.reset_counters(company.id, :contacts)
      end
    end
  end
end
