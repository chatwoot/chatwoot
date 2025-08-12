module Enterprise::Concerns::AccountUser
  extend ActiveSupport::Concern

  included do
    belongs_to :custom_role, optional: true
    belongs_to :agent_capacity_policy, class_name: 'Enterprise::AgentCapacityPolicy', optional: true
  end
end
