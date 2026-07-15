class Api::V1::Accounts::KanbanBoardsController < Api::V1::Accounts::BaseController
  DEFAULT_COLUMNS = [
    { name: 'New', color: 'blue', position: 10 },
    { name: 'In Progress', color: 'violet', position: 20 },
    { name: 'Done', color: 'teal', position: 30 }
  ].freeze

  before_action :fetch_kanban_board, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @kanban_boards = Current.account.kanban_boards.order(created_at: :asc)
  end

  def show; end

  def create
    KanbanBoard.transaction do
      @kanban_board = Current.account.kanban_boards.create!(kanban_board_params)
      DEFAULT_COLUMNS.each do |column|
        @kanban_board.kanban_columns.create!(column)
      end
    end
  end

  def update
    @kanban_board.update!(kanban_board_params)
  end

  def destroy
    @kanban_board.destroy!
    head :ok
  end

  private

  def fetch_kanban_board
    @kanban_board = Current.account.kanban_boards.find(params[:id])
  end

  def kanban_board_params
    params.require(:kanban_board).permit(:name, :description, :board_type)
  end
end
