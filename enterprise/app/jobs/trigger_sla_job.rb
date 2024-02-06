class TriggerSlaJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.find_each do |account|
      Rails.logger.info "Enqueuing AccountSlaJob for account #{account.id}"
      AccountSlaJob.perform_later(account)
    end
  end
end
