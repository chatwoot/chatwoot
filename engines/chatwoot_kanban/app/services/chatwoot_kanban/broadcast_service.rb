module ChatwootKanban
  # Single entry point for broadcasting changes via ActionCable.
  # Keeps payload shape consistent across the engine.
  module BroadcastService
    module_function

    # event examples:
    #   :card_created, :card_updated, :card_moved, :card_deleted,
    #   :column_created, :column_updated, :column_deleted, :columns_reordered,
    #   :comment_created, :comment_deleted,
    #   :checklist_item_toggled
    def broadcast(board:, event:, payload:)
      return unless board

      data = { event: event.to_s, payload: payload, at: Time.current.iso8601 }
      ChatwootKanban::BoardChannel.broadcast_to(board, data)
    rescue StandardError => e
      Rails.logger.warn("[ChatwootKanban] broadcast failed: #{e.message}")
    end
  end
end
