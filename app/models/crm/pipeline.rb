class Crm::Pipeline < ApplicationRecord
  belongs_to :account
  has_many :stages, class_name: 'Crm::Stage', foreign_key: 'crm_pipeline_id', dependent: :destroy
  has_many :leads, through: :stages

  validates :name, presence: true
  
  default_scope { order(display_order: :asc) }
end
