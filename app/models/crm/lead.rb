class Crm::Lead < ApplicationRecord
  belongs_to :account
  belongs_to :crm_stage, class_name: 'Crm::Stage'
  belongs_to :contact
  belongs_to :conversation, optional: true
  belongs_to :user, optional: true

  enum priority: { low: 0, medium: 1, high: 2 }

  validates :title, presence: true
end
