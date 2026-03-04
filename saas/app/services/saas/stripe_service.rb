class Saas::StripeService
  class << self
    def create_customer(account)
      customer = Stripe::Customer.create(
        name: account.name,
        email: account.support_email,
        metadata: { account_id: account.id }
      )
      customer.id
    end

    def create_checkout_session(account, plan)
      customer_id = ensure_customer(account)

      # Omit payment_method_types to let Stripe dynamically show
      # the best payment methods for the customer's region
      Stripe::Checkout::Session.create(
        customer: customer_id,
        line_items: [{
          price: plan.stripe_price_id,
          quantity: 1
        }],
        mode: 'subscription',
        success_url: checkout_success_url(account),
        cancel_url: checkout_cancel_url(account),
        metadata: {
          account_id: account.id,
          plan_id: plan.id
        },
        subscription_data: {
          metadata: {
            account_id: account.id,
            plan_id: plan.id
          }
        }
      )
    end

    def create_billing_portal_session(account)
      customer_id = account.stripe_customer_id
      raise 'No Stripe customer found' unless customer_id

      Stripe::BillingPortal::Session.create(
        customer: customer_id,
        return_url: billing_return_url(account)
      )
    end

    def handle_subscription_event(event)
      stripe_sub = event.data.object
      account_id = stripe_sub.metadata['account_id']&.to_i
      plan_id = stripe_sub.metadata['plan_id']&.to_i

      return unless account_id

      account = Account.find_by(id: account_id)
      return unless account

      case event.type
      when 'customer.subscription.created', 'customer.subscription.updated'
        upsert_subscription(account, stripe_sub, plan_id)
      when 'customer.subscription.deleted'
        cancel_subscription(account, stripe_sub)
      end
    end

    def handle_checkout_completed(event)
      session = event.data.object
      return unless session.mode == 'subscription'

      account_id = session.metadata['account_id']&.to_i
      return unless account_id

      # Subscription will be handled by customer.subscription.created event
    end

    private

    def ensure_customer(account)
      existing_customer_id = account.stripe_customer_id
      return existing_customer_id if existing_customer_id.present?

      customer_id = create_customer(account)

      subscription = account.saas_subscription || account.build_saas_subscription(
        saas_plan_id: Saas::Plan.active.order(:price_cents).first&.id,
        status: :incomplete
      )
      subscription.stripe_customer_id = customer_id
      subscription.save!

      customer_id
    end

    def upsert_subscription(account, stripe_sub, plan_id)
      plan = plan_id ? Saas::Plan.find_by(id: plan_id) : Saas::Plan.find_by(stripe_price_id: stripe_sub.items.data.first&.price&.id)
      return unless plan

      subscription = account.saas_subscription || account.build_saas_subscription
      old_plan = subscription.plan

      subscription.assign_attributes(
        plan: plan,
        stripe_subscription_id: stripe_sub.id,
        stripe_customer_id: stripe_sub.customer,
        status: map_stripe_status(stripe_sub.status),
        current_period_start: Time.zone.at(stripe_sub.current_period_start),
        current_period_end: Time.zone.at(stripe_sub.current_period_end),
        trial_end: stripe_sub.trial_end ? Time.zone.at(stripe_sub.trial_end) : nil
      )
      subscription.save!

      update_account_limits(account, plan)

      # Notify on plan change
      if old_plan && old_plan.id != plan.id
        Saas::BillingMailer.plan_changed(account, old_plan.name, plan.name).deliver_later
      end
    end

    def cancel_subscription(account, _stripe_sub)
      subscription = account.saas_subscription
      return unless subscription

      subscription.update!(status: :canceled)
      account.update!(limits: {})

      Saas::BillingMailer.subscription_canceled(account).deliver_later
    end

    def update_account_limits(account, plan)
      account.update!(limits: {
                        agents: plan.agent_limit,
                        inboxes: plan.inbox_limit
                      })
    end

    def map_stripe_status(status)
      case status
      when 'active' then :active
      when 'trialing' then :trialing
      when 'past_due' then :past_due
      when 'canceled' then :canceled
      when 'unpaid' then :unpaid
      else :incomplete
      end
    end

    def checkout_success_url(account)
      "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{account.id}/settings/billing?checkout=success"
    end

    def checkout_cancel_url(account)
      "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{account.id}/settings/billing?checkout=cancel"
    end

    def billing_return_url(account)
      "#{ENV.fetch('FRONTEND_URL', '')}/app/accounts/#{account.id}/settings/billing"
    end
  end
end
