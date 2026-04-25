class Api::V1::Accounts::Kanban::ColumnsController < Api::V1::Accounts::BaseController
  before_action :find_board
  before_action :find_column, only: [:update, :destroy]

  def index
    @columns = @board.columns.includes(:cards)
    render 'api/v1/accounts/kanban/columns/index'
  end

  def create
    @column = @board.columns.build(column_params)
    @column.position = KanbanColumn.next_position(@board.id)
    authorize @column
    @column.save!
    render 'api/v1/accounts/kanban/columns/show', status: :created
  end

  def update
    authorize @column
    @column.update!(column_params)
    render 'api/v1/accounts/kanban/columns/show'
  end

  def reorder
    positions = params.require(:positions)
    ActiveRecord::Base.transaction do
      positions.each do |item|
        @board.columns.find(item[:id]).update!(position: item[:position].to_f)
      end
    end
    head :ok
  end

  def destroy
    authorize @column
    @column.destroy!
    head :ok
  end

  private

  def find_board
    @board = Current.account.kanban_boards.find_by!(user: current_user)
  end

  def find_column
    @column = @board.columns.find(params[:id])
  end

  def column_params
    params.require(:column).permit(:name, :color)
  end
end
