class Subscription::ChargebeeService
  class << self
    def create_subscription(account)
      result = ChargeBee::Subscription.create(
        plan_id: Plan.paid_plan.id,
        customer: {
          email: account.users.administrator.try(:first).try(:email),
          first_name: account.name,
          company: account.name
        }
      )
      subscription = account.subscription
      subscription.stripe_customer_id = result.subscription.customer_id
      subscription.save
    rescue StandardError => e
      Raven.capture_exception(e)
    end

    def update_subscription(account)
      subscription = account.subscription
      agents_count = account.users.count
      ChargeBee::Subscription.update(subscription.stripe_customer_id, plan_quantity: agents_count)
    rescue StandardError => e
      Raven.capture_exception(e)
    end

    def cancel_subscription(account)
      subscription = account.subscription
      ChargeBee::Subscription.delete(subscription.stripe_customer_id)
    rescue StandardError => e
      Raven.capture_exception(e)
    end

    def reactivate_subscription(account)
      subscription = account.subscription
      ChargeBee::Subscription.reactivate(subscription.stripe_customer_id)
      subscription.active!
    rescue StandardError => e
      Raven.capture_exception(e)
    end

    def deactivate_subscription(account)
      subscription = account.subscription
      ChargeBee::Subscription.cancel(subscription.stripe_customer_id)
      subscription.cancelled!
    rescue StandardError => e
      Raven.capture_exception(e)
    end

    def hosted_page_url(account)
      subscription = account.subscription

      # result = ChargeBee::HostedPage.checkout_existing({
      #   :subscription => {
      #     :id => subscription.stripe_customer_id,
      #     :plan_id => Plan.paid_plan.id
      #   }
      # })

      result = ChargeBee::HostedPage.update_payment_method(
        customer: {
          id: subscription.stripe_customer_id
        }
      )
      result.hosted_page.url
    rescue StandardError => e
      Raven.capture_exception(e)
    end
  end
end
