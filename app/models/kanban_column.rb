class KanbanColumn < ApplicationRecord
  belongs_to :kanban_board

  has_many :cards, class_name: 'KanbanCard', dependent: :destroy

  validates :name, presence: true
  validates :position, presence: true, numericality: true

  default_scope { order(:position) }

  def self.next_position(board_id)
    where(kanban_board_id: board_id).maximum(:position).to_f + 1.0
  end
end
