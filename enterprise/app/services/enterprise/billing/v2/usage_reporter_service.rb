class Enterprise::Billing::V2::UsageReporterService < Enterprise::Billing::V2::BaseService
  def report_async(credits_used, feature)
    return unless should_report_usage?

    Enterprise::Billing::ReportUsageJob.perform_later(
      account_id: account.id,
      credits_used: credits_used,
      feature: feature
    )
  end

  def report(credits_used, feature, _metadata = {})
    return { success: false, message: 'Usage reporting disabled' } unless should_report_usage?

    identifier = usage_identifier(feature)

    # Stripe V2 meter events API
    response, _api_key = stripe_client.execute_request(
      :post,
      '/v1/billing/meter_events',
      headers: { 'Stripe-Version' => '2025-08-27.preview' },
      params: {
        :event_name => meter_event_name,
        'payload[value]' => credits_used.to_s,
        'payload[stripe_customer_id]' => stripe_customer_id,
        :identifier => identifier
      }
    )

    event_id = response.data[:identifier]
    Rails.logger.info "Usage reported: #{credits_used} credits for #{feature} (#{event_id})"

    { success: true, event_id: event_id, reported_credits: credits_used }
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe usage reporting failed: #{e.message}"
    { success: false, message: e.message }
  rescue StandardError => e
    Rails.logger.error "Usage reporting error: #{e.message}"
    { success: false, message: e.message }
  end

  private

  def should_report_usage?
    v2_enabled? &&
      stripe_customer_id.present? &&
      meter_event_name.present? &&
      v2_config[:usage_reporting_enabled] != false
  end

  def meter_event_name
    # Use the exact event name configured in the meter
    ENV['STRIPE_V2_METER_EVENT_NAME'] || v2_config[:meter_event_name].presence || 'ai_prompts'
  end

  def usage_identifier(feature)
    "acct_#{account.id}_#{feature}_#{SecureRandom.hex(8)}"
  end

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end
end
