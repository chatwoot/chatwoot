class Webhooks::StripeController < ActionController::API
  def process_payload
    byebug
    # Get the event payload and signature
    payload = request.body.read
    sig_header = request.headers["Stripe-Signature"]

    # Attempt to verify the signature. If successful, we'll handle the event
    begin
      Stripe::Webhook::Signature.verify_header(payload, sig_header, ENV["STRIPE_WEBHOOK_SIGNING_KEY"])
      EE::Billing::HandleStripeEventService.new.call(payload)
    # If we fail to verify the signature, then something was wrong with the request
    rescue Stripe::SignatureVerificationError
      head 400
      return
    end

    # We've successfully processed the event without blowing up
    head 200
  end
end
