class Captain::Routines::AgentTools::LookupStripePayments < Captain::Routines::AgentTools::Base
  description <<~TEXT.squish
    Search Stripe payments using a customer email and any available payment, charge, invoice, or subscription references.
    All lookup results are merged and deduplicated. At least one lookup key is required.
  TEXT
  params(
    type: 'object',
    properties: {
      customer_email: { type: 'string', minLength: 1 },
      stripe_references: {
        type: 'array',
        minItems: 1,
        uniqueItems: true,
        items: { type: 'string', minLength: 1 },
        description: 'Every available Stripe payment, charge, invoice, or subscription reference'
      }
    },
    anyOf: [
      { required: ['customer_email'] },
      { required: ['stripe_references'] }
    ],
    additionalProperties: false
  )

  def name = 'lookup_stripe_payments'

  def perform(tool_context, customer_email: nil, stripe_references: [])
    perform_operation(
      tool_context,
      'stripe.payments.search',
      customer_email: customer_email,
      stripe_references: stripe_references
    )
  end
end
