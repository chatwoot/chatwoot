class Enterprise::Webhooks::PaypalController < ActionController::API
  before_action :verify_webhook_signature

  def process_payload
    case params[:event_type]
    when 'BILLING.SUBSCRIPTION.ACTIVATED'
      handle_subscription_activated
    when 'BILLING.SUBSCRIPTION.UPDATED'  
      handle_subscription_updated
    when 'BILLING.SUBSCRIPTION.CANCELLED'
      handle_subscription_cancelled
    when 'BILLING.SUBSCRIPTION.SUSPENDED'
      handle_subscription_suspended
    when 'PAYMENT.SALE.COMPLETED'
      handle_payment_completed
    else
      Rails.logger.debug { "Unhandled PayPal event type: #{params[:event_type]}" }
    end

    head :ok
  rescue StandardError => e
    Rails.logger.error "PayPal webhook processing error: #{e.message}"
    head :bad_request
  end

  private

  def handle_subscription_activated
    subscription_data = params.dig(:resource)
    return unless subscription_data

    Enterprise::Billing::HandlePaypalEventService.new.perform(
      event_type: 'subscription_activated',
      data: subscription_data
    )
  end

  def handle_subscription_updated
    subscription_data = params.dig(:resource)
    return unless subscription_data

    Enterprise::Billing::HandlePaypalEventService.new.perform(
      event_type: 'subscription_updated', 
      data: subscription_data
    )
  end

  def handle_subscription_cancelled
    subscription_data = params.dig(:resource)
    return unless subscription_data

    Enterprise::Billing::HandlePaypalEventService.new.perform(
      event_type: 'subscription_cancelled',
      data: subscription_data
    )
  end

  def handle_subscription_suspended
    subscription_data = params.dig(:resource)
    return unless subscription_data

    Enterprise::Billing::HandlePaypalEventService.new.perform(
      event_type: 'subscription_suspended',
      data: subscription_data
    )
  end

  def handle_payment_completed
    payment_data = params.dig(:resource)
    return unless payment_data

    Enterprise::Billing::HandlePaypalEventService.new.perform(
      event_type: 'payment_completed',
      data: payment_data
    )
  end

  def verify_webhook_signature
    webhook_id = request.headers['PAYPAL-TRANSMISSION-ID']
    cert_id = request.headers['PAYPAL-CERT-ID'] 
    auth_algo = request.headers['PAYPAL-AUTH-ALGO']
    transmission_sig = request.headers['PAYPAL-TRANSMISSION-SIG']
    timestamp = request.headers['PAYPAL-TRANSMISSION-TIME']

    return head :unauthorized unless webhook_id && cert_id && auth_algo && transmission_sig && timestamp

    unless verify_paypal_signature(request.body.read, webhook_id, cert_id, auth_algo, transmission_sig, timestamp)
      head :unauthorized
      return
    end
  end

  def verify_paypal_signature(body, webhook_id, cert_id, auth_algo, transmission_sig, timestamp)
    paypal_webhook_secret = ENV.fetch('PAYPAL_WEBHOOK_SECRET', nil)
    return false unless paypal_webhook_secret

    expected_sig = OpenSSL::HMAC.hexdigest('sha256', paypal_webhook_secret, "#{timestamp}#{webhook_id}#{body}")
    ActiveSupport::SecurityUtils.secure_compare(expected_sig, transmission_sig)
  rescue StandardError => e
    Rails.logger.error "PayPal signature verification error: #{e.message}"
    false
  end
end