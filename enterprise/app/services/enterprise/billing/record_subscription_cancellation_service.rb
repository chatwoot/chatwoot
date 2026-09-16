class Enterprise::Billing::RecordSubscriptionCancellationService
  include BillingHelper

  pattr_initialize [:account!, :subscription!]

  def perform
    cancellations = account.internal_attributes.fetch('subscription_cancellations', {})
    return if cancellations.key?(subscription.id)

    account.update!(internal_attributes: account.internal_attributes.merge(
      'subscription_cancellations' => cancellations.merge(subscription.id => cancellation_details)
    ))
  end

  private

  def cancellation_details
    reason = subscription['cancellation_details']&.[]('reason')
    history = paid_history
    {
      'reason' => reason,
      'ended_at' => subscription['ended_at'],
      'trial_end' => subscription['trial_end'],
      'paid_invoice_id' => history[:invoice_id],
      'paid_at' => history[:paid_at],
      'category' => cancellation_category(reason, history)
    }
  end

  def paid_history
    history = { positive_payment: false, invoice_id: nil }
    Stripe::Invoice.list(customer: subscription.customer, subscription: subscription.id, status: 'paid', limit: 100).auto_paging_each do |invoice|
      next unless invoice.amount_paid.positive?

      history[:positive_payment] = true
      payment = qualifying_payment(invoice)
      return history.merge(payment) if payment
    end
    history
  end

  def qualifying_payment(invoice)
    paid_at = invoice['status_transitions']['paid_at']
    return unless paid_before_cancellation?(paid_at)

    positive_lines = invoice.lines.auto_paging_each.select { |line| line.amount.positive? }
    return if positive_lines.empty? || positive_lines.any? { |line| !paid_subscription_line?(line) }

    { invoice_id: invoice.id, paid_at: paid_at }
  end

  def paid_before_cancellation?(paid_at)
    paid_at.present? && subscription['ended_at'].present? && paid_at <= subscription['ended_at']
  end

  def paid_subscription_line?(line)
    details = line['parent']&.[]('subscription_item_details')
    return false unless details&.[]('subscription') == subscription.id

    product = line['pricing']['price_details']['product']
    plan = Enterprise::Billing::PlanConfiguration.find_plan_by_product_id(product)
    plan.present? && plan != Enterprise::Billing::PlanConfiguration.default_plan
  end

  def cancellation_category(reason, history)
    return 'non_paid' unless paid_plan?
    return 'trial_non_conversion' if subscription['trial_end'].present? && !history[:positive_payment]
    return 'unknown' unless history[:invoice_id]
    return 'payment_failure' if reason == 'payment_failed'
    return 'voluntary' if reason == 'cancellation_requested'

    'other'
  end

  def paid_plan?
    subscription_quantity(subscription).to_i.positive? &&
      !Enterprise::Billing::PlanConfiguration.plan_contains_product_id?(
        Enterprise::Billing::PlanConfiguration.default_plan, subscription_plan(subscription)['product']
      )
  end
end
