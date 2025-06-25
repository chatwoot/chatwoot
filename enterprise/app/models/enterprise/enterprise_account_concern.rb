module Enterprise::EnterpriseAccountConcern
  extend ActiveSupport::Concern

  included do
    has_many :sla_policies, dependent: :destroy_async
  end
end
