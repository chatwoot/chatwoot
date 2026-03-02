module Saas::Account
  extend ActiveSupport::Concern

  prepended do
    has_one :saas_subscription, class_name: 'Saas::Subscription', dependent: :destroy
    has_many :saas_ai_usage_records, class_name: 'Saas::AiUsageRecord', dependent: :destroy
    has_many :ai_agents, class_name: 'Saas::AiAgent', dependent: :destroy_async
    has_many :knowledge_bases, class_name: 'Saas::KnowledgeBase', dependent: :destroy_async
    has_many :agent_tools, class_name: 'Saas::AgentTool', through: :ai_agents
  end

  def saas_plan
    saas_subscription&.plan
  end

  def subscribed?
    saas_subscription&.active_or_trialing?
  end

  def stripe_customer_id
    saas_subscription&.stripe_customer_id
  end
end
