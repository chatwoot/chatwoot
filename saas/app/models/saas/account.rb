module Saas::Account
  extend ActiveSupport::Concern

  included do
    has_one :saas_subscription, class_name: 'Saas::Subscription', dependent: :destroy
    has_many :saas_ai_usage_records, class_name: 'Saas::AiUsageRecord', dependent: :destroy
  end

  def saas_plan
    saas_subscription&.plan
  end

  def subscribed?
    saas_subscription&.active_or_trialing?
  end

  def stripe_customer_id
    saas_subscription&.stripe_customer_id
  end
end
