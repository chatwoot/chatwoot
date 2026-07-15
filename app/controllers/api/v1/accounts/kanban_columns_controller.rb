class Api::V1::Accounts::KanbanColumnsController < Api::V1::Accounts::BaseController
  before_action :fetch_kanban_board
  before_action :fetch_kanban_column, only: [:update, :destroy]
  before_action :check_authorization

  def index
    @kanban_columns = @kanban_board.kanban_columns.ordered
  end

  def create
    @kanban_column = @kanban_board.kanban_columns.create!(kanban_column_params)
  end

  def update
    @kanban_column.update!(kanban_column_params)
  end

  def destroy
    @kanban_column.destroy!
    head :ok
  end

  private

  def fetch_kanban_board
    @kanban_board = Current.account.kanban_boards.find(params[:kanban_board_id])
  end

  def fetch_kanban_column
    @kanban_column = @kanban_board.kanban_columns.find(params[:id])
  end

  def kanban_column_params
    params.require(:kanban_column).permit(:name, :description, :color, :position, :win_probability)
  end
end
