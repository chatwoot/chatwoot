class Api::V1::Accounts::KanbanCardsController < Api::V1::Accounts::BaseController
  before_action :fetch_kanban_board
  before_action :fetch_kanban_card, only: [:show, :update, :destroy, :move]
  before_action :check_authorization

  def index
    @kanban_cards = @kanban_board.kanban_cards.includes(:kanban_column, conversation: [:contact, :inbox]).ordered
  end

  def show; end

  def create
    @kanban_card = @kanban_board.kanban_cards.create!(kanban_card_params.merge(conversation: conversation))
  end

  def update
    @kanban_card.update!(kanban_card_params)
  end

  def move
    target_column = @kanban_board.kanban_columns.find(move_params[:kanban_column_id])

    KanbanCard.transaction do
      @kanban_card.move_to!(column: target_column, position: move_params[:position] || next_position_for(target_column))
      resequence_column(target_column)
    end
  end

  def destroy
    @kanban_card.destroy!
    head :ok
  end

  private

  def fetch_kanban_board
    @kanban_board = Current.account.kanban_boards.find(params[:kanban_board_id])
  end

  def fetch_kanban_card
    @kanban_card = @kanban_board.kanban_cards.find(params[:id])
  end

  def kanban_card_params
    params.require(:kanban_card).permit(:kanban_column_id, :position, metadata: {})
  end

  def move_params
    params.require(:kanban_card).permit(:kanban_column_id, :position, ordered_card_ids: [])
  end

  def conversation
    conversation_id = params.dig(:kanban_card, :conversation_id)
    conversation_display_id = params.dig(:kanban_card, :conversation_display_id)

    return Current.account.conversations.find(conversation_id) if conversation_id.present?

    Current.account.conversations.find_by!(display_id: conversation_display_id)
  end

  def next_position_for(column)
    (column.kanban_cards.maximum(:position) || 0) + 10
  end

  def resequence_column(column)
    ordered_ids = Array(move_params[:ordered_card_ids]).map(&:to_i)
    cards = column.kanban_cards.ordered.where(id: ordered_ids.presence || column.kanban_cards.ids).index_by(&:id)

    ordered_ids = cards.keys if ordered_ids.blank?
    ordered_ids.each_with_index do |card_id, index|
      cards[card_id]&.update_column(:position, (index + 1) * 10) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
