module ChatwootKanban
  # ActionCable channel for real-time Kanban updates.
  #
  # Frontend subscribes per-board after loading the board view. Mutations
  # (column reorder, card create/update/move/delete, comments, labels,
  # checklists) broadcast to `BoardChannel.broadcast_to(board, payload)`.
  class BoardChannel < ::ApplicationCable::Channel
    def subscribed
      board = ChatwootKanban::Board.find_by(id: params[:board_id])
      return reject if board.nil?
      return reject unless current_user_member_of_account?(board.account_id)

      stream_for board
    end

    def unsubscribed
      stop_all_streams
    end

    private

    def current_user_member_of_account?(account_id)
      # ApplicationCable::Connection in Chatwoot exposes `current_user`.
      current_user.present? && current_user.accounts.exists?(id: account_id)
    end
  end
end
