class Enterprise::Billing::V2::UsageReporterService < Enterprise::Billing::V2::BaseService
  def report(credits_used, _feature)
    return { success: false, message: 'V2 billing not enabled' } unless v2_enabled?
    return { success: false, message: 'No Stripe customer' } if stripe_customer_id.blank?

    meter_event = Stripe::Billing::MeterEvent.create(
      {
        event_name: meter_event_name,
        payload: {
          value: credits_used.to_s,
          stripe_customer_id: stripe_customer_id
        },
        identifier: "#{account.id}_#{SecureRandom.hex(8)}"
      },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )

    { success: true, event_id: meter_event.identifier }
  rescue StandardError => e
    { success: false, message: e.message }
  end

  private

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end

  def meter_event_name
    custom_attribute('stripe_meter_event_name') || 'ai_prompts'
  end
end
