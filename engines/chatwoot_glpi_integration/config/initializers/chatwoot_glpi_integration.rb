# Optional auto-escalation: when a Kanban card lands in a column flagged as
# "escalate to GLPI", create a ticket automatically. Wire by adding to a board:
#
#   board.update!(settings: board.settings.merge('glpi_escalation_column_ids' => [<col_id>]))
#
# The listener attaches to the same dispatcher Kanban uses.

Rails.application.config.after_initialize do
  next unless defined?(Rails.configuration.dispatcher) && Rails.configuration.dispatcher

  Rails.configuration.dispatcher.subscribe('kanban.card.moved') do |_event, time, payload|
    next unless payload.is_a?(Hash)

    card           = payload[:card]
    to_column_id   = payload[:to_column_id]
    next if card.nil? || to_column_id.nil?

    board    = card.board
    targets  = Array(board.settings['glpi_escalation_column_ids']).map(&:to_i)
    next unless targets.include?(to_column_id)

    # Skip if already linked
    next if ChatwootGlpiIntegration::TicketLink.exists?(account_id: board.account_id, kanban_card_id: card.id)

    conn = ChatwootGlpiIntegration::Connection.find_by(account_id: board.account_id, active: true)
    next unless conn

    Thread.new do
      begin
        ChatwootGlpiIntegration::CreateTicketService.new(
          connection:   conn,
          kanban_card:  card,
          conversation: card.conversation
        ).call
      rescue StandardError => e
        Rails.logger.warn("[Glpi auto-escalation] failed: #{e.message}")
      end
    end
  end
rescue StandardError => e
  Rails.logger.warn("[ChatwootGlpiIntegration] init warning: #{e.message}")
end
