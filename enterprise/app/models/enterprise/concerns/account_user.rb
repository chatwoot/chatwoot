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

    Enterprise::CreateStripeCustomerJob.perform_later(account)
  end

  # The row lock makes the check and the claim atomic, so concurrent callbacks queue one job.
  # The administrator who became one first claims it (ties go to the lower id), so admins added together still elect one.
  # A locale with its own currency picks it or USD on the billing page first; that choice creates the customer with the trial.
  def claim_cloud_trial
    account.with_lock do
      next false if account.custom_attributes.values_at('stripe_customer_id', 'is_creating_customer', 'trial_pending').any?(&:present?)
      next false if earlier_administrators.exists?

      claim = { 'trial_pending' => true }
      claim['is_creating_customer'] = true unless account.billing_currency_selection_required?
      account.update!(custom_attributes: account.custom_attributes.merge(claim))
      claim.key?('is_creating_customer')
    end
  end

  def earlier_administrators
    table = self.class.arel_table
    earlier = table[:updated_at].lt(updated_at).or(table[:updated_at].eq(updated_at).and(table[:id].lt(id)))
    account.account_users.administrator.where.not(id: id).where(earlier)
  end
end
