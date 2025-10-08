class Enterprise::Billing::ReportUsageJob < ApplicationJob
  queue_as :low

  def perform(account_id:, credits_used:, feature:)
    account = Account.find_by(id: account_id)
    return if account.nil?
    return unless account.custom_attributes&.[]('stripe_billing_version').to_i == 2

    service = V2::UsageReporterService.new(account: account)
    service.report(credits_used, feature)
  end
end
