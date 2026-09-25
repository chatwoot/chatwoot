class Sla::TriggerSlasForAccountsJob < ApplicationJob
  queue_as :within_1_minute

  def perform
    # SLA is a premium feature; skip accounts that have policies left over from a downgrade.
    Account.feature_sla.joins(:sla_policies).distinct.find_each do |account|
      Rails.logger.info "Enqueuing ProcessAccountAppliedSlasJob for account #{account.id}"
      Sla::ProcessAccountAppliedSlasJob.perform_later(account)
    end
  end
end
