# Modelo para gerenciar planos de billing por conta (SaaS)
class AccountBillingPlan < ApplicationRecord
  belongs_to :account

  # Planos disponíveis
  PLANS = {
    'free' => {
      name: 'Free',
      price: 0,
      limits: {
        agents: 3,
        inboxes: 2,
        conversations_per_month: 100,
        contacts: 1000,
        storage_mb: 100
      },
      features: %w[basic_chat email_support]
    },
    'starter' => {
      name: 'Starter',
      price: 29,
      limits: {
        agents: 10,
        inboxes: 5,
        conversations_per_month: 1000,
        contacts: 10_000,
        storage_mb: 1000
      },
      features: %w[basic_chat email_support automations team_management]
    },
    'professional' => {
      name: 'Professional',
      price: 99,
      limits: {
        agents: 50,
        inboxes: 20,
        conversations_per_month: 10_000,
        contacts: 100_000,
        storage_mb: 10_000
      },
      features: %w[basic_chat email_support automations team_management custom_attributes audit_logs sla]
    },
    'enterprise' => {
      name: 'Enterprise',
      price: 299,
      limits: {
        agents: -1, # unlimited
        inboxes: -1,
        conversations_per_month: -1,
        contacts: -1,
        storage_mb: -1
      },
      features: %w[basic_chat email_support automations team_management custom_attributes audit_logs sla custom_roles saml captain_integration]
    }
  }.freeze

  validates :plan_name, presence: true, inclusion: { in: PLANS.keys }
  validates :account_id, uniqueness: true

  # Callbacks para atualizar contadores
  after_create :update_usage_counters
  after_update :update_usage_counters, if: :saved_change_to_plan_name?

  def plan_details
    PLANS[plan_name]
  end

  def within_limit?(resource, count)
    limit = plan_details.dig(:limits, resource)
    return true if limit.nil? || limit == -1 # unlimited or no limit defined

    count <= limit
  end

  def has_feature?(feature)
    plan_details[:features].include?(feature)
  end

  def upgrade_to!(new_plan)
    return false unless PLANS.key?(new_plan)

    update!(
      plan_name: new_plan,
      upgraded_at: Time.current,
      previous_plan: plan_name
    )
  end

  def usage_percentage(resource)
    limit = plan_details.dig(:limits, resource)
    return 0 if limit.nil? || limit == -1 # unlimited or no limit defined

    current_usage = case resource
                    when :agents
                      current_agents_count
                    when :inboxes
                      current_inboxes_count
                    when :conversations_per_month
                      current_conversations_month_count
                    else
                      0
                    end

    return 0 if limit.zero?

    (current_usage.to_f / limit * 100).round(2)
  end

  def can_add?(resource)
    within_limit?(resource, current_count(resource) + 1)
  end

  def current_count(resource)
    case resource
    when :agents
      current_agents_count
    when :inboxes
      current_inboxes_count
    when :conversations_per_month
      current_conversations_month_count
    when :contacts
      account.contacts.count
    else
      0
    end
  end

  private

  def current_agents_count
    account.account_users.count
  end

  def current_inboxes_count
    account.inboxes.count
  end

  def current_conversations_month_count
    account.conversations.where('created_at >= ?', 1.month.ago).count
  end

  def update_usage_counters
    update!(
      current_agents_count: account.account_users.count,
      current_inboxes_count: account.inboxes.count,
      current_conversations_count: account.conversations.count
    )
  end
end
