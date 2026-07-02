class Autonomia::Prospecting::List < ApplicationRecord
  self.table_name = 'autonomia_prospecting_lists'

  belongs_to :account
  belongs_to :user, optional: true

  has_many :list_leads, class_name: 'Autonomia::Prospecting::ListLead', foreign_key: :prospect_list_id, dependent: :destroy,
                        inverse_of: :list
  has_many :leads, through: :list_leads, source: :lead

  enum status: { active: 0, archived: 1 }

  validates :name, presence: true
end
