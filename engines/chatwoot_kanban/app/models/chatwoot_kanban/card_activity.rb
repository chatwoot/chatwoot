module ChatwootKanban
  # Audit log of card movements / edits. Cheap, append-only.
  #
  # Schema (table: chatwoot_kanban_card_activities):
  #   id, card_id, actor_id (FK users.id, nullable),
  #   action (string, eg 'moved' | 'created' | 'assigned' | 'commented'),
  #   payload (jsonb), created_at
  class CardActivity < ApplicationRecord
    self.table_name = 'chatwoot_kanban_card_activities'

    ACTIONS = %w[created moved updated assigned commented archived].freeze

    belongs_to :card,  class_name: 'ChatwootKanban::Card', inverse_of: :activities
    belongs_to :actor, class_name: '::User', optional: true

    validates :action, presence: true, inclusion: { in: ACTIONS }

    # No updated_at — activities are immutable.
    self.record_timestamps = true
  end
end
