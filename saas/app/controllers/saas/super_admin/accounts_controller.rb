module Saas::SuperAdmin::AccountsController
  extend ActiveSupport::Concern

  def assign_plan
    account = Account.find(params[:id])
    plan = Saas::Plan.find(params[:saas_plan_id])

    subscription = account.saas_subscription || account.build_saas_subscription
    subscription.assign_attributes(
      saas_plan_id: plan.id,
      status: plan.free? ? :active : subscription.status,
      current_period_start: Time.current,
      current_period_end: 30.days.from_now
    )
    subscription.save!(validate: false)

    Saas::StripeService.send(:update_account_limits, account, plan)

    redirect_back(fallback_location: [:super_admin, account], notice: "Plan changed to #{plan.name}")
  end
end
