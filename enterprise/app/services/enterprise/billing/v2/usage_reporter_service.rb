class Enterprise::Billing::V2::UsageReporterService < Enterprise::Billing::V2::BaseService
  def report_async(credits_used, feature)
    return unless should_report_usage?

    Enterprise::Billing::ReportUsageJob.perform_later(
      account_id: account.id,
      credits_used: credits_used,
      feature: feature
    )
  end

  def report(credits_used, feature, _metadata: {})
    return { success: false, message: 'Usage reporting disabled' } unless should_report_usage?

    with_stripe_error_handling do
      payload = build_meter_payload(credits_used, feature)

      response = stripe_client.execute_request(
        :post,
        '/v1/billing/meter_events',
        headers: { 'Idempotency-Key' => payload[:identifier] },
        params: payload
      )

      response_data = extract_response_data(response)
      event_id = response_data['id'] || payload[:identifier]

      log_usage_payload(credits_used, feature, payload)

      { success: true, event_id: event_id, reported_credits: credits_used }
    end
  rescue StandardError => e
    Rails.logger.error "Failed to report usage for account #{account.id}: #{e.message}"
    { success: false, message: e.message }
  end

  private

  # No HTTP client; use Stripe gem's generic execute_request to support preview endpoints

  def build_meter_payload(credits_used, feature)
    {
      identifier: usage_identifier(feature),
      event_name: meter_event_name,
      timestamp: Time.current.to_i,
      payload: {
        value: credits_used,
        stripe_customer_id: stripe_customer_id,
        feature: feature
      }
    }
  end

  def log_usage_payload(credits_used, feature, payload)
    Rails.logger.info "Usage Reported: #{credits_used} credits for account #{account.id} (#{feature})"
    Rails.logger.info "Stripe meter ID: #{v2_config[:meter_id]}"
    Rails.logger.debug { "Stripe meter event payload: #{payload}" }
  end

  def should_report_usage?
    v2_enabled? &&
      stripe_customer_id.present? &&
      meter_event_name.present? &&
      v2_config[:usage_reporting_enabled] != false
  end

  def meter_event_name
    v2_config[:meter_event_name].presence || "captain_prompts_#{Rails.env}"
  end

  def usage_identifier(feature)
    "acct_#{account.id}_#{feature}_#{SecureRandom.hex(8)}"
  end

  def stripe_customer_id
    custom_attribute('stripe_customer_id')
  end

  def extract_response_data(response)
    return response if response.is_a?(Hash)
    return response.data if response.respond_to?(:data)

    {}
  end
end
