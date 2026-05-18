module ChatwootKanban
  class ChecklistItem < ApplicationRecord
    self.table_name = 'chatwoot_kanban_checklist_items'

    belongs_to :card,         class_name: 'ChatwootKanban::Card', inverse_of: :checklist_items
    belongs_to :completed_by, class_name: '::User', optional: true

    validates :title,    presence: true, length: { maximum: 200 }
    validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    before_save :stamp_completion

    private

    def stamp_completion
      if completed_changed?
        self.completed_at    = completed ? Time.current : nil
        self.completed_by_id = nil unless completed
      end
    end
  end
end
