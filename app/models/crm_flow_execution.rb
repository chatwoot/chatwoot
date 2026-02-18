class CrmFlowExecution < ApplicationRecord
  belongs_to :crm_flow
  belongs_to :conversation, optional: true
  belongs_to :contact, optional: true

  STATUSES = %w[pending success partial failed].freeze

  validates :status, inclusion: { in: STATUSES }
end
