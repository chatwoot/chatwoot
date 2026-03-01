class Saas::Webhooks::StripeController < ActionController::API
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
              begin
                JSON.parse(payload, object_class: Stripe::StripeObject)
              rescue JSON::ParserError
                head :bad_request and return
              end
            end

    handle_event(event)
    head :ok
  end

  private

  def handle_event(event)
    case event.type
    when 'checkout.session.completed'
      Saas::StripeService.handle_checkout_completed(event)
    when 'customer.subscription.created',
         'customer.subscription.updated',
         'customer.subscription.deleted'
      Saas::StripeService.handle_subscription_event(event)
    when 'invoice.payment_failed'
      handle_payment_failed(event)
    end
  end

  def handle_payment_failed(event)
    invoice = event.data.object
    customer_id = invoice.customer

    subscription = Saas::Subscription.find_by(stripe_customer_id: customer_id)
    return unless subscription

    subscription.update!(status: :past_due)
  end
end
