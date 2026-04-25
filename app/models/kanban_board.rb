class KanbanBoard < ApplicationRecord
  belongs_to :account
  belongs_to :user

  has_many :columns, class_name: 'KanbanColumn', dependent: :destroy
  has_many :cards, class_name: 'KanbanCard', dependent: :destroy

  validates :account_id, uniqueness: { scope: :user_id }
end
