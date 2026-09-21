class CopilotRunItem < ApplicationRecord
  belongs_to :copilot_run
  belongs_to :source_item, class_name: 'CopilotRunItem', optional: true
  attr_readonly :captured, :source_item_id, :dataset_key, :resource_id, :resource_type, :position
  validates :dataset_key, :resource_type, :resource_id, :position, presence: true
  validates :state, inclusion: { in: %w[captured pending resolved unresolved] }

  def evidence
    source_item ? source_item.captured : captured
  end
end
