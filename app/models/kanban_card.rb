# == Schema Information
#
# Table name: kanban_cards
#
#  id               :bigint           not null, primary key
#  notes            :text
#  position         :float            default(1.0), not null
#  potential_value  :decimal(15, 2)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  contact_id       :bigint           not null
#  created_by_id    :bigint           not null
#  kanban_board_id  :bigint           not null
#  kanban_column_id :bigint           not null
#
# Indexes
#
#  index_kanban_cards_on_contact_id                     (contact_id)
#  index_kanban_cards_on_contact_id_unique              (contact_id) UNIQUE
#  index_kanban_cards_on_created_by_id                  (created_by_id)
#  index_kanban_cards_on_kanban_board_id                (kanban_board_id)
#  index_kanban_cards_on_kanban_column_id               (kanban_column_id)
#  index_kanban_cards_on_kanban_column_id_and_position  (kanban_column_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (kanban_board_id => kanban_boards.id)
#  fk_rails_...  (kanban_column_id => kanban_columns.id)
#
class KanbanCard < ApplicationRecord
  belongs_to :kanban_column
  belongs_to :kanban_board
  belongs_to :contact
  belongs_to :created_by, class_name: 'User'

  has_many :activities, class_name: 'KanbanCardActivity', dependent: :destroy
  has_many :schedules, class_name: 'KanbanCardSchedule', dependent: :destroy

  validates :position, presence: true, numericality: true
  validates :contact_id, uniqueness: { message: 'already has a Kanban card' }
  validates :potential_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  default_scope { order(:position) }

  def self.next_position(column_id, board_id = nil)
    scope = where(kanban_column_id: column_id)
    scope = scope.where(kanban_board_id: board_id) if board_id
    scope.maximum(:position).to_f + 1.0
  end

  def self.position_between(before_pos, after_pos)
    (before_pos.to_f + after_pos.to_f) / 2.0
  end
end
