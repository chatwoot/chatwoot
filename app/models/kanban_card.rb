class KanbanCard < ApplicationRecord
  belongs_to :kanban_column
  belongs_to :kanban_board
  belongs_to :contact
  belongs_to :created_by, class_name: 'User'

  has_many :activities, class_name: 'KanbanCardActivity', dependent: :destroy

  validates :position, presence: true, numericality: true
  validates :contact_id, uniqueness: { scope: :kanban_board_id, message: 'already exists in this board' }
  validates :potential_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  default_scope { order(:position) }

  def self.next_position(column_id)
    where(kanban_column_id: column_id).maximum(:position).to_f + 1.0
  end

  def self.position_between(before_pos, after_pos)
    (before_pos.to_f + after_pos.to_f) / 2.0
  end
end
