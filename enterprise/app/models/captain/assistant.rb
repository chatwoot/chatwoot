class Captain::Assistant < ApplicationRecord
  self.table_name = 'captain_assistants'

  belongs_to :account

  validates :name, presence: true
  validates :account_id, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  scope :for_account, ->(account_id) { where(account_id: account_id) }
end
