# == Schema Information
#
# Table name: kanban_cards
#
#  id               :bigint           not null, primary key
#  entered_stage_at :datetime         not null
#  notes            :text
#  position         :float            default(1.0), not null
#  potential_value  :decimal(15, 2)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  contact_id       :bigint           not null
#  conversation_id  :bigint
#  created_by_id    :bigint           not null
#  kanban_board_id  :bigint           not null
#  kanban_column_id :bigint           not null
#
# Indexes
#
#  index_kanban_cards_on_column_and_entered_stage_at    (kanban_column_id,entered_stage_at)
#  index_kanban_cards_on_contact_id                     (contact_id)
#  index_kanban_cards_on_conversation_id                (conversation_id)
#  index_kanban_cards_on_conversation_id_unique         (conversation_id) UNIQUE WHERE (conversation_id IS NOT NULL)
#  index_kanban_cards_on_created_by_id                  (created_by_id)
#  index_kanban_cards_on_kanban_board_id                (kanban_board_id)
#  index_kanban_cards_on_kanban_column_id               (kanban_column_id)
#  index_kanban_cards_on_kanban_column_id_and_position  (kanban_column_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => nullify
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (kanban_board_id => kanban_boards.id)
#  fk_rails_...  (kanban_column_id => kanban_columns.id)
#
class KanbanCard < ApplicationRecord
  belongs_to :kanban_column
  belongs_to :kanban_board
  belongs_to :contact
  belongs_to :conversation, optional: true
  belongs_to :created_by, class_name: 'User'

  has_many :activities, class_name: 'KanbanCardActivity', dependent: :destroy
  has_many :schedules, class_name: 'KanbanCardSchedule', dependent: :destroy

  # DEPRECATED: ordering is now deterministic via `entered_stage_at` (or
  # `conversation.created_at` for auto_receive columns). The `position` field
  # is kept for backwards compatibility and will be removed in a future PR.
  validates :position, presence: true, numericality: true
  validates :conversation_id, uniqueness: { allow_nil: true, message: 'already has a Kanban card' }
  validates :potential_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Managed exclusively by the before_save callback `touch_entered_stage_at`.
  # Do not assign directly — manual edits break FIFO ordering guarantees.
  before_save :touch_entered_stage_at

  scope :ordered_for_column, lambda { |column|
    if column.column_function == 'auto_receive'
      left_outer_joins(:conversation)
        .order(Arel.sql('COALESCE(conversations.created_at, kanban_cards.created_at) ASC'))
        .order(:id)
    else
      order(:entered_stage_at).order(:id)
    end
  }

  def self.next_position(column_id, board_id = nil)
    scope = where(kanban_column_id: column_id)
    scope = scope.where(kanban_board_id: board_id) if board_id
    scope.maximum(:position).to_f + 1.0
  end

  def self.position_between(before_pos, after_pos)
    (before_pos.to_f + after_pos.to_f) / 2.0
  end

  private

  def touch_entered_stage_at
    if new_record?
      self.entered_stage_at ||= Time.current
    elsif kanban_column_id_changed?
      self.entered_stage_at = Time.current
    end
  end
end
