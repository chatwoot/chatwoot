module Enterprise::Concerns::AccountUser
  extend ActiveSupport::Concern

  included do
    belongs_to :custom_role, optional: true
    belongs_to :agent_capacity_policy, optional: true

    after_commit :start_cloud_trial, on: [:create, :update], if: -> { administrator? && saved_change_to_role? }
  end

  private

  # A Stripe-billed cloud account starts its trial when it gets its first administrator, the person it bills. At signup
  # that is the moment the account is created; for Super Admin and Platform API accounts it is when an admin is added
  # or an agent is promoted.
  def start_cloud_trial
    return unless Enterprise::Billing::TrialService.enabled? && account.billing_provider == Account::DEFAULT_BILLING_PROVIDER
    return unless claim_cloud_trial

    Enterprise::CreateStripeCustomerJob.perform_later(account, trial_end: Enterprise::Billing::TrialService::TRIAL_DAYS.days.from_now.to_i)
  end

  # The row lock makes the check and the is_creating_customer claim atomic, so concurrent callbacks queue one job.
  def claim_cloud_trial
    account.with_lock do
      next false if account.custom_attributes.values_at('stripe_customer_id', 'is_creating_customer').any?(&:present?)
      next false if account.account_users.administrator.where.not(id: id).exists?

      account.update!(custom_attributes: account.custom_attributes.merge('is_creating_customer' => true))
    end
  end
end
