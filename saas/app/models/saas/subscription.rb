class Saas::Subscription < ApplicationRecord
  self.table_name = 'saas_subscriptions'

  belongs_to :account, class_name: '::Account', optional: false
  belongs_to :plan, class_name: 'Saas::Plan', foreign_key: :saas_plan_id, inverse_of: :subscriptions

  enum :status, { active: 0, trialing: 1, past_due: 2, canceled: 3, unpaid: 4, incomplete: 5 }

  validates :account_id, uniqueness: { scope: :status, conditions: -> { where(status: %i[active trialing]) },
                                       message: 'already has an active subscription' }

  scope :current, -> { where(status: %i[active trialing]) }

  def active_or_trialing?
    active? || trialing?
  end

  def usage_limits
    plan.usage_limits
  end

  def period_active?
    current_period_end.nil? || current_period_end > Time.current
  end

  def trial_active?
    trialing? && trial_end.present? && trial_end > Time.current
  end
end
