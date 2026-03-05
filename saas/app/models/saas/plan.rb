class Saas::Plan < ApplicationRecord
  self.table_name = 'saas_plans'

  has_many :subscriptions, class_name: 'Saas::Subscription', foreign_key: :saas_plan_id,
                           dependent: :restrict_with_error, inverse_of: :plan

  validates :name, presence: true, uniqueness: { scope: :interval }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :interval, inclusion: { in: %w[month year] }
  validates :agent_limit, numericality: { greater_than: 0 }
  validates :inbox_limit, numericality: { greater_than: 0 }
  validates :ai_tokens_monthly, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :monthly, -> { where(interval: 'month') }
  scope :annual, -> { where(interval: 'year') }

  def free?
    price_cents.zero?
  end

  def annual?
    interval == 'year'
  end

  def monthly?
    interval == 'month'
  end

  # Returns the base plan name without the " Anual" suffix.
  def base_name
    name.delete_suffix(' Anual')
  end

  # Checks whether a specific feature key is enabled in the plan.
  # For boolean features, returns true/false.
  # For numeric limits (e.g. ai_agents_limit), returns the value (-1 = unlimited).
  def feature_enabled?(feature_key)
    value = features&.dig(feature_key.to_s)
    return false if value.nil?

    value.is_a?(Integer) ? value != 0 : value.present?
  end

  # Returns the numeric limit for a feature key, or nil if feature is absent.
  # A value of -1 means unlimited.
  def feature_limit(feature_key)
    features&.dig(feature_key.to_s)
  end

  def usage_limits
    {
      agents: agent_limit,
      inboxes: inbox_limit,
      ai_tokens_monthly: ai_tokens_monthly
    }
  end
end
