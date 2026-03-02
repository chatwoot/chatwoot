class Saas::Webhooks::StripeController < ActionController::API
  # Stripe best practice: return 200 immediately, process asynchronously.
  # Reference: https://docs.stripe.com/webhooks#best-practices
  def process_payload
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV.fetch('STRIPE_WEBHOOK_SECRET', nil)

    event = if endpoint_secret.present?
              begin
                Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
              rescue JSON::ParserError
                head :bad_request and return
              rescue Stripe::SignatureVerificationError
                head :bad_request and return
              end
            else
              # Development only — no signature verification
              if Rails.env.production?
                Rails.logger.warn('[Stripe] Webhook received without endpoint_secret in production!')
                head :bad_request and return
              end
              begin
                JSON.parse(payload, object_class: Stripe::StripeObject)
              rescue JSON::ParserError
                head :bad_request and return
              end
            end

    # Return 200 immediately — Stripe retries on non-2xx
    head :ok

    # Process event asynchronously in a background job
    Saas::StripeWebhookJob.perform_later(event.to_json)
  end
end
