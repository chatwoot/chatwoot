class Migration::BackfillCompaniesContactsCountJob < ApplicationJob
  queue_as :within_1_day

  def perform
    Company.find_in_batches(batch_size: 100) do |company_batch|
      company_batch.each do |company|
        Company.reset_counters(company.id, :contacts)
      end
    end
  end
end
