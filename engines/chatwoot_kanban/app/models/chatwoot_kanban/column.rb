module ChatwootKanban
  # An ordered column inside a board ("Backlog", "Doing", ...).
  #
  # Schema (table: chatwoot_kanban_columns):
  #   id, board_id, name, position, color, wip_limit (int, null), created_at, updated_at
  class Column < ApplicationRecord
    self.table_name = 'chatwoot_kanban_columns'

    belongs_to :board,
               class_name: 'ChatwootKanban::Board',
               inverse_of: :columns

    has_many :cards, -> { order(position: :asc) },
             class_name: 'ChatwootKanban::Card',
             foreign_key: :column_id,
             dependent: :destroy,
             inverse_of: :column

    validates :name,     presence: true, length: { maximum: 80 }
    validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :wip_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

    scope :ordered, -> { order(position: :asc) }

    def wip_reached?
      wip_limit.present? && cards.count >= wip_limit
    end
  end
end
