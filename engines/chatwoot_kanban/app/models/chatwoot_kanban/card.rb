module ChatwootKanban
  # A card lives in exactly one column. It MAY be linked to a Chatwoot conversation
  # (so moving a card across columns updates the conversation context), but it can
  # also be a free-form card (internal task).
  class Card < ApplicationRecord
    self.table_name = 'chatwoot_kanban_cards'

    PRIORITIES = { low: 0, medium: 1, high: 2, urgent: 3 }.freeze
    enum :priority, PRIORITIES, prefix: true

    belongs_to :column,       class_name: 'ChatwootKanban::Column', inverse_of: :cards
    belongs_to :conversation, class_name: '::Conversation', optional: true
    belongs_to :assignee,     class_name: '::User',         optional: true
    belongs_to :created_by,   class_name: '::User',         optional: true

    has_one  :board, through: :column

    has_many :activities,
             class_name: 'ChatwootKanban::CardActivity',
             foreign_key: :card_id,
             dependent: :destroy,
             inverse_of: :card

    has_many :comments,
             class_name: 'ChatwootKanban::Comment',
             foreign_key: :card_id,
             dependent: :destroy,
             inverse_of: :card

    has_many :checklist_items,
             -> { order(position: :asc) },
             class_name: 'ChatwootKanban::ChecklistItem',
             foreign_key: :card_id,
             dependent: :destroy,
             inverse_of: :card

    has_many :card_labels,
             class_name: 'ChatwootKanban::CardLabel',
             foreign_key: :card_id,
             dependent: :destroy,
             inverse_of: :card

    has_many :labels, through: :card_labels, source: :label

    validates :title,    presence: true, length: { maximum: 200 }
    validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    scope :active,         -> { where(archived_at: nil) }
    scope :archived,       -> { where.not(archived_at: nil) }
    scope :overdue,        -> { active.where('due_at < ?', Time.current).where.not(due_at: nil) }
    scope :for_account,    ->(account_id) { joins(column: :board).where(chatwoot_kanban_boards: { account_id: account_id }) }
    scope :recently_moved, -> { order(updated_at: :desc) }

    def archive!
      update!(archived_at: Time.current)
    end

    def unarchive!
      update!(archived_at: nil)
    end

    def archived?
      archived_at.present?
    end

    def account_id
      board&.account_id
    end

    def checklist_progress
      total = checklist_items.size
      return nil if total.zero?

      done = checklist_items.where(completed: true).count
      ((done.to_f / total) * 100).round
    end
  end
end
