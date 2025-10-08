class Enterprise::Billing::V2::UsageAnalyticsService < Enterprise::Billing::V2::BaseService
  def fetch_usage_summary
    return { success: false, message: 'Not on V2 billing' } unless v2_enabled?
    return { success: false, message: 'No Stripe customer' } if stripe_customer_id.blank?

    with_stripe_error_handling do
      # Get current month's usage from Stripe
      start_time = Time.current.beginning_of_month.to_i
      end_time = Time.current.to_i

      # For now, return mock data as Stripe Billing Meters require setup
      # In production, this would call Stripe's usage API
      Rails.logger.info "Fetching usage for customer #{stripe_customer_id} from #{start_time} to #{end_time}"

      # Calculate usage from local credit transactions for current month
      total_used = account.credit_transactions
                          .where(transaction_type: 'use',
                                 created_at: Time.current.all_month)
                          .sum(:amount)

      {
        success: true,
        total_usage: total_used,
        period_start: Time.zone.at(start_time),
        period_end: Time.zone.at(end_time),
        source: 'local' # Indicate this is from local data
      }
    end
  end

  private

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end
end
