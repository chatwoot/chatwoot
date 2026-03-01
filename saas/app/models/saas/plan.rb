class Saas::Plan < ApplicationRecord
  self.table_name = 'saas_plans'

  has_many :subscriptions, class_name: 'Saas::Subscription', foreign_key: :saas_plan_id,
                           dependent: :restrict_with_error, inverse_of: :plan

  validates :name, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :interval, inclusion: { in: %w[month year] }
  validates :agent_limit, numericality: { greater_than: 0 }
  validates :inbox_limit, numericality: { greater_than: 0 }
  validates :ai_tokens_monthly, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }

  def free?
    price_cents.zero?
  end

  def usage_limits
    {
      agents: agent_limit,
      inboxes: inbox_limit,
      ai_tokens_monthly: ai_tokens_monthly
    }
  end
end
