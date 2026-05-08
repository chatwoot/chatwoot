module Kanban
  class CardSyncService
    POSITION_RETRY_LIMIT = 3

    def initialize(conversation:)
      @conversation = conversation
      @contact = conversation.contact
      @account = conversation.account
    end

    # Single entry point. Order matters when status AND assignee both change:
    # 1) sync_to_assignee moves card to the new assignee's board
    # 2) move_to_resolution_column then moves to won/lost within that new board
    # When assignee is nil and conversation is not resolved, card stays put.
    def sync
      sync_to_assignee if @conversation.assignee.present?
      move_to_resolution_column if @conversation.resolved? && resolution_classification_type
    end

    private

    def sync_to_assignee
      assignee = @conversation.assignee
      return if skip_assignee?(assignee)

      board = @account.kanban_boards.find_or_create_by!(user: assignee)
      receive_column = KanbanColumn.auto_receive_for(@account)
      return unless receive_column

      with_position_retry do
        card = KanbanCard.find_by(conversation_id: @conversation.id)
        if card.nil?
          KanbanCard.create!(
            conversation: @conversation,
            contact: @contact,
            kanban_board: board,
            kanban_column: receive_column,
            created_by: assignee,
            position: KanbanCard.next_position(receive_column.id, board.id)
          )
        elsif needs_resync?(card, board)
          card.update!(
            kanban_board: board,
            kanban_column: receive_column,
            position: KanbanCard.next_position(receive_column.id, board.id)
          )
        end
      end
    end

    # Move when board changes OR when card is stuck in won/lost but conversation
    # is no longer resolved (reopen scenario).
    def needs_resync?(card, target_board)
      card.kanban_board_id != target_board.id ||
        (!@conversation.resolved? && card.kanban_column.column_type.in?(%w[won lost]))
    end

    def move_to_resolution_column
      card = KanbanCard.find_by(conversation_id: @conversation.id)
      return unless card

      target_column = @account.kanban_columns.find_by(column_type: resolution_classification_type)
      return unless target_column

      with_position_retry do
        card.update!(
          kanban_column: target_column,
          position: KanbanCard.next_position(target_column.id, card.kanban_board_id)
        )
      end
    end

    def resolution_classification_type
      classification = @conversation.classification
      return nil unless classification
      return :won if classification.won?
      return :lost if classification.lost?

      nil
    end

    def skip_assignee?(user)
      return true if user.blank?

      !user.kanban_enabled
    end

    def with_position_retry
      attempts = 0
      begin
        yield
      rescue ActiveRecord::RecordNotUnique
        attempts += 1
        retry if attempts < POSITION_RETRY_LIMIT
        raise
      end
    end
  end
end
