module Saas::Concerns::Account
  extend ActiveSupport::Concern

  included do
    after_create :assign_default_plan
  end

  private

  def assign_default_plan
    default_plan = Saas::Plan.active.order(:price_cents).first
    return unless default_plan

    Saas::Subscription.new(
      account_id: id,
      saas_plan_id: default_plan.id,
      status: default_plan.free? ? :active : :trialing,
      trial_end: default_plan.free? ? nil : 14.days.from_now,
      current_period_start: Time.current,
      current_period_end: 30.days.from_now
    ).save!(validate: false)
  end
end
