class Crm::Stage < ApplicationRecord
  belongs_to :crm_pipeline, class_name: 'Crm::Pipeline'
  has_many :leads, class_name: 'Crm::Lead', foreign_key: 'crm_stage_id', dependent: :destroy

  enum stage_type: { standard: 0, won: 1, lost: 2 }

  validates :name, presence: true
  
  default_scope { order(display_order: :asc) }
end
