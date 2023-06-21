module Enterprise::EnterpriseConversationConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :sla_policy, optional: true
  end
end
