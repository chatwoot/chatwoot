class Autonomia::Prospecting::Search < ApplicationRecord
  self.table_name = 'autonomia_prospecting_searches'

  belongs_to :account
  belongs_to :user, optional: true
  has_many :leads, class_name: 'Autonomia::Prospecting::Lead', foreign_key: :prospect_search_id, dependent: :nullify, inverse_of: :search

  enum status: { pending: 0, completed: 1, failed: 2, cached: 3 }

  validates :query, presence: true
  validates :provider, presence: true
  validates :requested_limit, numericality: { only_integer: true, greater_than: 0 }
  validates :consumed_api_units, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
