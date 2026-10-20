class Webhooks::StripeAppController < ActionController::API
  def events
    secret = GlobalConfig.get_value('STRIPE_APP_WEBHOOK_SECRET')
    return head :service_unavailable if secret.blank?

    event = Stripe::Webhook.construct_event(request.raw_post, request.headers['Stripe-Signature'], secret)
    if event.type == 'account.application.deauthorized'
      return head :bad_request unless event[:account].is_a?(String) && event[:account].match?(/\Aacct_[A-Za-z0-9]+\z/)

      Integrations::Stripe::UninstallationService.new(event: event).perform
    end
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end
end
