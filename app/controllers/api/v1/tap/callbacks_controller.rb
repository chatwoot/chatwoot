class Api::V1::Tap::CallbacksController < ActionController::API
  # Handle redirect callback after payment (redirect.url)
  def callback
    payment_link = find_payment_link

    if payment_link
      process_callback(payment_link)
      redirect_to success_or_failure_url(payment_link), allow_other_host: true
    else
      redirect_to payment_failure_url(error: 'Payment link not found'), allow_other_host: true
    end
  end

  # Handle webhook notification (post.url)
  def webhook
    payment_link = find_payment_link

    if payment_link
      process_callback(payment_link)
      head :ok
    else
      Rails.logger.warn "Tap webhook received for unknown payment link: #{reference_id}"
      head :not_found
    end
  end

  private

  def find_payment_link
    PaymentLink.find_by(external_payment_id: reference_id, provider: 'tap')
  end

  def reference_id
    params.dig(:reference, :invoice) || params[:reference_invoice] || params[:id]
  end

  def invoice_status
    params[:status]&.upcase
  end

  def process_callback(payment_link)
    case invoice_status
    when 'PAID', 'PAYMENT_CAPTURED', 'PAYMENT_SETTLED'
      payment_link.mark_as_paid!(callback_data)
    when 'CANCELLED'
      payment_link.mark_as_cancelled!(callback_data)
    when 'EXPIRED'
      payment_link.mark_as_expired!
    when 'PAYMENT_FAILED'
      payment_link.mark_as_failed!(callback_data)
    else
      Rails.logger.info "Tap callback received with status: #{invoice_status} for payment link: #{payment_link.id}"
    end
  end

  def callback_data
    params.as_json.merge(processed_at: Time.current.iso8601)
  end

  def success_or_failure_url(payment_link)
    if payment_link.paid?
      payment_success_url(track_id: payment_link.external_payment_id)
    else
      payment_failure_url(track_id: payment_link.external_payment_id)
    end
  end

  def payment_success_url(options = {})
    base_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    query = options.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    "#{base_url}/payment/success?#{query}"
  end

  def payment_failure_url(options = {})
    base_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    query = options.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    "#{base_url}/payment/failure?#{query}"
  end
end
