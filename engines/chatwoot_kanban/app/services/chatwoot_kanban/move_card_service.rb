module ChatwootKanban
  # Encapsulates drag-and-drop "move card" semantics: cross-column moves,
  # reordering, WIP enforcement, position rebalancing, activity logging,
  # ActionCable broadcast, and dispatcher event.
  class MoveCardService
    class WipLimitExceeded < StandardError; end

    def initialize(card:, to_column_id:, position:, actor: nil)
      @card           = card
      @to_column_id   = to_column_id
      @to_position    = position
      @actor          = actor
    end

    def call
      ChatwootKanban::Card.transaction do
        from_column_id = @card.column_id
        target_column  = ChatwootKanban::Column.find(@to_column_id)

        ensure_same_board!(target_column)
        ensure_wip_capacity!(target_column, from_column_id)

        ChatwootKanban::Card.active
          .where(column_id: from_column_id)
          .where('position > ?', @card.position)
          .update_all('position = position - 1')

        ChatwootKanban::Card.active
          .where(column_id: target_column.id)
          .where('position >= ?', @to_position)
          .update_all('position = position + 1')

        @card.update!(column_id: target_column.id, position: @to_position)
        @card.activities.create!(
          actor_id: @actor&.id,
          action: 'moved',
          payload: { from_column_id: from_column_id, to_column_id: target_column.id, position: @to_position }
        )

        sync_conversation!(target_column)
        broadcast!(from_column_id: from_column_id, to_column_id: target_column.id)
        dispatch_event(from_column_id: from_column_id, to_column_id: target_column.id)
      end

      @card.reload
    end

    private

    def ensure_same_board!(target_column)
      return if target_column.board_id == @card.column.board_id

      raise ActiveRecord::RecordInvalid.new(@card),
            'Card cannot be moved to a column belonging to a different board'
    end

    def ensure_wip_capacity!(target_column, from_column_id)
      return if target_column.wip_limit.blank?
      return if target_column.id == from_column_id

      occupied = ChatwootKanban::Card.active.where(column_id: target_column.id).count
      return if occupied < target_column.wip_limit

      raise WipLimitExceeded,
            "Column '#{target_column.name}' is at its WIP limit (#{target_column.wip_limit})."
    end

    def sync_conversation!(target_column)
      return if @card.conversation_id.blank?

      board    = target_column.board
      done_ids = Array(board.settings['done_column_ids']).map(&:to_i)
      return unless done_ids.include?(target_column.id)

      conversation = @card.conversation
      return unless conversation
      return if conversation.resolved?

      conversation.toggle_status if conversation.respond_to?(:toggle_status)
    rescue StandardError => e
      Rails.logger.warn("[ChatwootKanban] conversation sync failed: #{e.message}")
    end

    def broadcast!(from_column_id:, to_column_id:)
      ChatwootKanban::BroadcastService.broadcast(
        board: @card.board,
        event: :card_moved,
        payload: {
          card_id: @card.id,
          from_column_id: from_column_id,
          to_column_id: to_column_id,
          position: @to_position
        }
      )
    end

    def dispatch_event(from_column_id:, to_column_id:)
      return unless defined?(::Rails.configuration.dispatcher)

      ::Rails.configuration.dispatcher.dispatch(
        'kanban.card.moved',
        Time.current,
        card: @card,
        from_column_id: from_column_id,
        to_column_id: to_column_id,
        performed_by: @actor
      )
    rescue StandardError => e
      Rails.logger.warn("[ChatwootKanban] dispatch failed: #{e.message}")
    end
  end
end
