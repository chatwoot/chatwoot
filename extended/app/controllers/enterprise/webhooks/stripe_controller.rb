class Enterprise::Webhooks::StripeController < ActionController::API
  def process_payload
    Rails.logger.info 'Stripe webhooks are disabled in this version.'
    head :ok
  end
end
