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

    meter_event = create_meter_event(credits_used, feature)
    { success: true, event_id: meter_event.identifier, reported_credits: credits_used }
  rescue StandardError => e
    { success: false, message: e.message }
  end

  private

  def should_report_usage?
    v2_enabled? &&
      stripe_customer_id.present? &&
      meter_event_name.present?
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

  def create_meter_event(credits_used, feature)
    identifier = usage_identifier(feature)
    Stripe::Billing::MeterEvent.create(
      {
        event_name: meter_event_name,
        payload: { value: credits_used.to_s, stripe_customer_id: stripe_customer_id },
        identifier: identifier
      },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end
end
