# == Schema Information
#
# Table name: kanban_columns
#
#  id              :bigint           not null, primary key
#  color           :string
#  description     :text
#  name            :string           not null
#  position        :integer          default(0), not null
#  win_probability :decimal(5, 2)    default(100.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  kanban_board_id :bigint           not null
#
# Indexes
#
#  index_kanban_columns_on_account_id                    (account_id)
#  index_kanban_columns_on_kanban_board_id               (kanban_board_id)
#  index_kanban_columns_on_kanban_board_id_and_name      (kanban_board_id,name) UNIQUE
#  index_kanban_columns_on_kanban_board_id_and_position  (kanban_board_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (kanban_board_id => kanban_boards.id)
#
class KanbanColumn < ApplicationRecord
  belongs_to :account
  belongs_to :kanban_board
  has_many :kanban_cards, dependent: :destroy

  before_validation :set_account
  before_validation :set_position, on: :create

  validates :name, presence: true, uniqueness: { scope: :kanban_board_id }
  validates :description, length: { maximum: 120 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :win_probability, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :ordered, -> { order(position: :asc, id: :asc) }

  private

  def set_account
    self.account_id ||= kanban_board&.account_id
  end

  def set_position
    return if position.positive?

    self.position = (kanban_board&.kanban_columns&.maximum(:position) || 0) + 10
  end
end
