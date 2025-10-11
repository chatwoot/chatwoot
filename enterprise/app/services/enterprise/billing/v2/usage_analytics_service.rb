class Enterprise::Billing::V2::UsageAnalyticsService < Enterprise::Billing::V2::BaseService
  def fetch_usage_summary
    return { success: false, message: 'Not on V2 billing' } unless v2_enabled?

    end_time = Time.current
    start_time = end_time.beginning_of_month

    transactions = account.credit_transactions
                          .where(transaction_type: 'use', created_at: start_time..end_time)

    {
      success: true,
      total_usage: transactions.sum(:amount),
      credits_remaining: total_credits,
      period_start: start_time,
      period_end: end_time,
      usage_by_feature: transactions.group("metadata->>'feature'").sum(:amount)
    }
  end

  def recent_transactions(limit: 10)
    account.credit_transactions
           .order(created_at: :desc)
           .limit(limit)
  end

  private

  def total_credits
    Enterprise::Billing::V2::CreditManagementService.new(account: account).total_credits
  end
end
