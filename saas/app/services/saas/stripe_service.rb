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

    def create_checkout_session(account, plan, success_url: nil, cancel_url: nil)
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
        allow_promotion_codes: true,
        success_url: success_url || checkout_success_url(account),
        cancel_url: cancel_url || checkout_cancel_url(account),
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
      customer_id = ensure_customer(account)

      Stripe::BillingPortal::Session.create(
        customer: customer_id,
        return_url: billing_return_url(account)
      )
    end

    def handle_subscription_event(event)
      stripe_sub = event.data.object
      account_id = stripe_sub.metadata['account_id']&.to_i
      plan_id = stripe_sub.metadata['plan_id']&.to_i

      account = Account.find_by(id: account_id) if account_id
      account ||= find_account_by_stripe_customer(stripe_sub.customer)
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
      if existing_customer_id.present?
        begin
          customer = Stripe::Customer.retrieve(existing_customer_id)
          return existing_customer_id unless customer.respond_to?(:deleted) && customer.deleted

          Rails.logger.warn("[StripeService] Deleted customer #{existing_customer_id} for account #{account.id}, creating new one")
        rescue Stripe::InvalidRequestError
          Rails.logger.warn("[StripeService] Invalid customer #{existing_customer_id} for account #{account.id}, creating new one")
        end
      end

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
      return unless old_plan && old_plan.id != plan.id

      Saas::BillingMailer.plan_changed(account, old_plan.name, plan.name).deliver_later
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

    def find_account_by_stripe_customer(customer_id)
      return unless customer_id

      sub = Saas::Subscription.find_by(stripe_customer_id: customer_id)
      sub&.account
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
