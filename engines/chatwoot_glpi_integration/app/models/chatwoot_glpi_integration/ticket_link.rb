module ChatwootGlpiIntegration
  # Bridge between a GLPI ticket and either a Chatwoot conversation or a
  # ChatwootKanban::Card (or both — common case is to link all three).
  class TicketLink < ApplicationRecord
    self.table_name = 'chatwoot_glpi_ticket_links'

    SYNC_DIRECTIONS = %w[both inbound outbound].freeze

    belongs_to :account,      class_name: '::Account'
    belongs_to :conversation, class_name: '::Conversation',           optional: true
    belongs_to :kanban_card,  class_name: 'ChatwootKanban::Card',     optional: true

    validates :glpi_ticket_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :glpi_ticket_id, uniqueness: { scope: :account_id }
    validates :sync_direction, inclusion: { in: SYNC_DIRECTIONS }
    validate  :has_at_least_one_target

    scope :for_account, ->(id) { where(account_id: id) }
    scope :active_sync, ->     { where(sync_direction: %w[both inbound outbound]) }

    private

    def has_at_least_one_target
      return if conversation_id.present? || kanban_card_id.present?

      errors.add(:base, 'must link to a conversation or a Kanban card')
    end
  end
end
