# Provisions a trial when a new account is created.
# Grants 14 days on Pro plan with 500 AI credits (whichever runs out first).
#
class BillingListener < BaseListener
  def account_created(event)
    account = event.data[:account]
    return unless account.is_a?(Account)

    account.grant_trial!(days: 14, credits: 500, plan_key: 'pro_monthly')
  end
end
