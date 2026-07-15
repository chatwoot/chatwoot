# == Schema Information
#
# Table name: kanban_cards
#
#  id               :bigint           not null, primary key
#  metadata         :jsonb            not null
#  position         :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  conversation_id  :bigint           not null
#  kanban_board_id  :bigint           not null
#  kanban_column_id :bigint           not null
#
# Indexes
#
#  index_kanban_cards_on_account_id                           (account_id)
#  index_kanban_cards_on_conversation_id                      (conversation_id)
#  index_kanban_cards_on_kanban_board_id                      (kanban_board_id)
#  index_kanban_cards_on_kanban_board_id_and_conversation_id  (kanban_board_id,conversation_id) UNIQUE
#  index_kanban_cards_on_kanban_column_id                     (kanban_column_id)
#  index_kanban_cards_on_kanban_column_id_and_position        (kanban_column_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (kanban_board_id => kanban_boards.id)
#  fk_rails_...  (kanban_column_id => kanban_columns.id)
#
class KanbanCard < ApplicationRecord
  belongs_to :account
  belongs_to :kanban_board
  belongs_to :kanban_column
  belongs_to :conversation

  before_validation :set_account
  before_validation :set_position, on: :create

  validates :conversation_id, uniqueness: { scope: :kanban_board_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :validate_board_scope
  validate :validate_conversation_scope

  scope :ordered, -> { order(position: :asc, id: :asc) }

  def move_to!(column:, position:)
    update!(kanban_column: column, position: position)
  end

  private

  def set_account
    self.account_id ||= kanban_board&.account_id
  end

  def set_position
    return if position.positive?

    self.position = (kanban_column&.kanban_cards&.maximum(:position) || 0) + 10
  end

  def validate_board_scope
    return if kanban_column.blank? || kanban_board.blank?

    errors.add(:kanban_column_id, :invalid) if kanban_column.kanban_board_id != kanban_board_id
  end

  def validate_conversation_scope
    return if conversation.blank? || account_id.blank?

    errors.add(:conversation_id, :invalid) if conversation.account_id != account_id
  end
end
