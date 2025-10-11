class Enterprise::Billing::V2::UsageReporterService < Enterprise::Billing::V2::BaseService
  def report(credits_used, _feature = nil)
    return { success: false, message: 'V2 billing not enabled' } unless v2_enabled?
    return { success: false, message: 'Missing Stripe configuration' } unless valid_configuration?

    event = Stripe::Billing::MeterEvent.create(
      meter_event_params(credits_used),
      stripe_api_options
    )

    { success: true, event_id: event.identifier }
  rescue Stripe::StripeError => e
    { success: false, message: e.message }
  end

  private

  def valid_configuration?
    custom_attribute('stripe_customer_id').present? &&
      custom_attribute('stripe_meter_event_name').present?
  end

  def meter_event_params(credits_used)
    {
      event_name: custom_attribute('stripe_meter_event_name'),
      payload: {
        value: credits_used.to_s,
        stripe_customer_id: custom_attribute('stripe_customer_id')
      },
      identifier: "#{account.id}_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
    }
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end
end
