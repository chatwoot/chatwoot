require 'administrate/field/base'

class BillingPlanActionsField < Administrate::Field::Base
  def to_s
    data
  end

  def billing_plan_status(account)
    return 'Sem plano' unless account.billing_plan

    if account.billing_plan.active?
      'Ativo'
    else
      'Pausado'
    end
  end

  def billing_plan_name(account)
    return 'N/A' unless account.billing_plan

    plan_details = AccountBillingPlan::PLANS[account.billing_plan.plan_name.to_sym]
    plan_details ? plan_details[:name] : account.billing_plan.plan_name.humanize
  end

  def pause_billing_plan_path(account)
    Rails.application.routes.url_helpers.super_admin_account_billing_plan_path(account, action: :pause)
  end

  def resume_billing_plan_path(account)
    Rails.application.routes.url_helpers.super_admin_account_billing_plan_path(account, action: :resume)
  end
end
