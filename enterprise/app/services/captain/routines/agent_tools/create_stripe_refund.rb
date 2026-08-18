class Captain::Routines::AgentTools::CreateStripeRefund < Captain::Routines::AgentTools::Base
  description 'Create a Stripe refund for a payment returned by lookup_stripe_payments'
  params(
    type: 'object',
    properties: {
      payment_id: { type: 'string' },
      reason: { type: 'string', enum: Captain::Routines::Operations::Actions::StripeRefundCreate::REASONS }
    },
    required: %w[payment_id reason],
    additionalProperties: false
  )

  def name = 'create_stripe_refund'

  def perform(tool_context, payment_id:, reason:)
    perform_operation(tool_context, 'stripe.refunds.create', payment_id: payment_id, reason: reason)
  end
end
