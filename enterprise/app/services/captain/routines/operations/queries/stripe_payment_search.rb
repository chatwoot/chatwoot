require 'digest'

class Captain::Routines::Operations::Queries::StripePaymentSearch < Captain::Routines::Operations::Query
  returns :collection, of: :stripe_payment

  configure(
    name: 'stripe.payments.search', effect: 'read',
    description: 'Search Stripe payments using every supplied email and payment, charge, invoice, or subscription ' \
                 'reference; merge and deduplicate all matches.',
    arguments: {
      customer_email: 'customer email address',
      stripe_references: 'array of Stripe payment, charge, invoice, or subscription references; arbitrary reference strings are accepted'
    }
  )

  def execute(customer_email: nil, stripe_references: [])
    lookup_keys = build_lookup_keys(customer_email, stripe_references)
    raise ArgumentError, 'A customer email or at least one Stripe reference is required' if lookup_keys.empty?

    stripe_state = context.integration_state('stripe')
    refunds = stripe_state.fetch('refunds', {})
    payments = merge_payments(lookup_keys.flat_map { |lookup| fixture_payments(lookup, customer_email) }).map do |payment|
      refund = refunds[payment.fetch('id')]
      refund ? payment.merge('refunded' => true, 'refund_id' => refund.fetch('id')) : payment
    end
    payment_store = stripe_state.fetch('payments') { |key| stripe_state[key] = {} }
    payments.each { |payment| payment_store[payment.fetch('id')] = payment }
    payments
  end

  private

  def build_lookup_keys(customer_email, stripe_references)
    lookups = []
    lookups << { 'type' => 'customer_email', 'value' => customer_email } if customer_email.present?
    Array(stripe_references).compact_blank.each do |reference|
      lookups << { 'type' => reference_type(reference), 'value' => reference }
    end
    lookups.uniq { |lookup| [lookup.fetch('type'), lookup.fetch('value').downcase] }
  end

  def reference_type(reference)
    return 'payment_reference' if reference.start_with?('pi_')
    return 'charge_reference' if reference.start_with?('ch_')
    return 'invoice_reference' if reference.start_with?('in_')
    return 'subscription_reference' if reference.start_with?('sub_')

    'stripe_reference'
  end

  def fixture_payments(lookup, customer_email)
    lookup_key = lookup.fetch('value')
    base_id = payment_id_for(lookup)
    payments = if lookup_key.match?(/double|duplicate/i)
                 duplicate_payments(base_id, customer_email)
               elsif lookup_key.match?(/trial/i)
                 [trial_payment(base_id, customer_email)]
               else
                 [payment(base_id, customer_email, started_at - 30.days, 'subscription_cycle')]
               end

    payments.map { |stripe_payment| stripe_payment.merge('matched_by' => [lookup]) }
  end

  def payment_id_for(lookup)
    return lookup.fetch('value') if lookup.fetch('type') == 'payment_reference'

    "pi_#{Digest::SHA256.hexdigest(lookup.fetch('value').downcase).first(16)}"
  end

  def merge_payments(payments)
    payments.each_with_object({}) do |payment, merged|
      existing = merged[payment.fetch('id')]
      if existing
        existing['matched_by'] |= payment.fetch('matched_by')
      else
        merged[payment.fetch('id')] = payment
      end
    end.values
  end

  def duplicate_payments(base_id, customer_email)
    [
      payment(base_id, customer_email, started_at - 30.days, 'subscription_cycle'),
      payment("#{base_id}_duplicate", customer_email, started_at - 30.days + 2.minutes, 'duplicate')
        .merge('duplicate_of' => base_id)
    ]
  end

  def trial_payment(id, customer_email)
    payment(id, customer_email, started_at - 1.day, 'subscription_cycle').merge(
      'trial' => {
        'ended_at' => (started_at - 1.day - 5.minutes).iso8601,
        'converted_to_paid' => true
      }
    )
  end

  def payment(id, customer_email, created_at, billing_reason)
    {
      'id' => id,
      'customer_email' => customer_email,
      'status' => 'succeeded',
      'amount_cents' => 4900,
      'currency' => 'usd',
      'billing_reason' => billing_reason,
      'created_at' => created_at.iso8601,
      'refundable' => true,
      'refunded' => false
    }
  end
end
