module ChatwootGlpiIntegration
  # Pulls the latest GLPI ticket state and applies it to the linked Chatwoot
  # conversation and/or Kanban card.
  class SyncTicketService
    # GLPI status codes: 1 New, 2 Processing-assigned, 3 Processing-planned,
    # 4 Pending, 5 Solved, 6 Closed.
    GLPI_DONE_STATUSES = [5, 6].freeze

    def initialize(link)
      @link       = link
      @connection = Connection.find_by!(account_id: link.account_id)
    end

    def call
      ticket = GlpiClient.new(@connection).get_ticket(@link.glpi_ticket_id)
      status_id   = ticket['status'].to_i
      status_name = glpi_status_name(status_id)

      @link.update!(last_status: status_name, last_synced_at: Time.current)

      if @link.sync_direction.in?(%w[both inbound])
        apply_to_conversation(ticket, status_id)
        apply_to_card(ticket, status_id)
      end

      @link
    rescue GlpiClient::NotFoundError
      Rails.logger.info("[Glpi] Ticket #{@link.glpi_ticket_id} not found, marking link inactive")
      @link.update!(sync_direction: 'inbound', last_status: 'deleted', last_synced_at: Time.current)
      @link
    end

    private

    def apply_to_conversation(ticket, status_id)
      conv = @link.conversation
      return unless conv

      if GLPI_DONE_STATUSES.include?(status_id) && !conv.resolved?
        conv.toggle_status if conv.respond_to?(:toggle_status)
      end
    end

    def apply_to_card(ticket, status_id)
      card = @link.kanban_card
      return unless card

      board = card.board
      done_ids = Array(board.settings['done_column_ids']).map(&:to_i)
      return if done_ids.empty?
      return unless GLPI_DONE_STATUSES.include?(status_id)

      target = ChatwootKanban::Column.where(id: done_ids, board_id: board.id).first
      return if target.nil? || card.column_id == target.id

      ChatwootKanban::MoveCardService.new(
        card:         card,
        to_column_id: target.id,
        position:     (target.cards.maximum(:position) || -1) + 1
      ).call
    end

    def glpi_status_name(id)
      { 1 => 'new', 2 => 'assigned', 3 => 'planned', 4 => 'pending',
        5 => 'solved', 6 => 'closed' }[id] || "status_#{id}"
    end
  end
end
