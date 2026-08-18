require 'digest'

class Captain::Routines::Operations::Actions::StripeRefundCreate < Captain::Routines::Operations::Action
  REASONS = %w[duplicate_payment accidental_trial_charge].freeze

  configure(
    name: 'stripe.refunds.create', effect: 'external_write',
    description: 'Create a Stripe refund for a payment previously returned by the payment search.',
    arguments: {
      payment_id: 'Stripe payment ID returned by stripe.payments.search',
      reason: "one of #{REASONS.join(', ')}"
    },
    required: %w[payment_id reason]
  )

  def execute(payment_id:, reason:)
    raise ArgumentError, "Invalid refund reason '#{reason}'" unless reason.to_s.in?(REASONS)

    stripe_state = context.integration_state('stripe')
    payment = stripe_state.fetch('payments', {})[payment_id]
    raise ArgumentError, "Payment '#{payment_id}' must be looked up before it can be refunded" unless payment

    refunds = stripe_state.fetch('refunds') { |key| stripe_state[key] = {} }
    raise ArgumentError, "Payment '#{payment_id}' was already refunded in this execution" if refunds.key?(payment_id)

    refund = build_refund(payment_id, payment, reason)
    refunds[payment_id] = refund
    payment['refunded'] = true
    payment['refund_id'] = refund.fetch('id')
    refund
  end

  private

  def build_refund(payment_id, payment, reason)
    {
      'id' => "re_#{Digest::SHA256.hexdigest("#{context.id}:#{payment_id}").first(16)}",
      'payment_id' => payment_id,
      'status' => 'succeeded',
      'amount_cents' => payment.fetch('amount_cents'),
      'currency' => payment.fetch('currency'),
      'reason' => reason,
      'created_at' => Time.current.iso8601
    }
  end
end
