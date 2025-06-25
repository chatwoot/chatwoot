class UpdateReportingEventsFirstResponseTime < ActiveRecord::Migration[6.1]
  def change
    ::Account.find_in_batches do |account_batch|
      Rails.logger.info "Updated reporting events till #{account_batch.first.id}\n"
      account_batch.each do |account|
        Migration::UpdateFirstResponseTimeInReportingEventsJob.perform_later(account)
      end
    end
  end
end
