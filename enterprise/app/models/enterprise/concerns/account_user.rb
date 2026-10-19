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

    begin
      Enterprise::CreateStripeCustomerJob.perform_later(account)
    rescue StandardError
      # Only the job clears is_creating_customer, so release it here; trial_pending stays, so the billing page's setup
      # retry still creates the trial.
      account.update!(custom_attributes: account.reload.custom_attributes.except('is_creating_customer'))
      raise
    end
  end

  # The row lock makes the check and the is_creating_customer claim atomic, so concurrent callbacks queue one job.
  # The administrator who became one first claims it (ties go to the lower id), so admins added together still elect one.
  def claim_cloud_trial
    account.with_lock do
      next false if account.custom_attributes.values_at('stripe_customer_id', 'is_creating_customer').any?(&:present?)
      next false if earlier_administrators.exists?

      account.update!(custom_attributes: account.custom_attributes.merge('is_creating_customer' => true, 'trial_pending' => true))
    end
  end

  def earlier_administrators
    table = self.class.arel_table
    earlier = table[:updated_at].lt(updated_at).or(table[:updated_at].eq(updated_at).and(table[:id].lt(id)))
    account.account_users.administrator.where.not(id: id).where(earlier)
  end
end
