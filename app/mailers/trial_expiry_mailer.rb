class TrialExpiryMailer < ApplicationMailer
  def trial_expired(user, account)
    @user = user
    @account = account
    @account_plan = account.weave_core_account_plans.first
    @upgrade_url = billing_upgrade_url(account)

    mail(
      to: @user.email,
      subject: "Your #{@account.name} trial has expired"
    )
  end

  def trial_expiring_soon(user, account, days_remaining)
    @user = user
    @account = account
    @account_plan = account.weave_core_account_plans.first
    @days_remaining = days_remaining
    @upgrade_url = billing_upgrade_url(account)

    mail(
      to: @user.email,
      subject: "Your #{@account.name} trial expires in #{days_remaining} days"
    )
  end

  private

  def billing_upgrade_url(account)
    # This should point to your billing/upgrade page
    "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/accounts/#{account.id}/settings/billing"
  end
end