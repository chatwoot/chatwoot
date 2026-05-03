class Api::V1::Accounts::Kanban::ColumnsController < Api::V1::Accounts::BaseController
  def index
    @columns = Current.account.kanban_columns
    render 'api/v1/accounts/kanban/columns/index'
  end

  def create
    @column = Current.account.kanban_columns.build(column_params)
    @column.position = KanbanColumn.next_position(Current.account.id)
    authorize @column
    @column.save!
    render 'api/v1/accounts/kanban/columns/show', status: :created
  end

  def update
    @column = Current.account.kanban_columns.find(params[:id])
    authorize @column
    @column.update!(column_params)
    render 'api/v1/accounts/kanban/columns/show'
  end

  def reorder
    authorize Current.account.kanban_columns.new, :update?
    positions = params.require(:positions)
    ActiveRecord::Base.transaction do
      positions.each do |item|
        Current.account.kanban_columns.find(item[:id]).update!(position: item[:position].to_f)
      end
    end
    head :ok
  end

  def destroy
    @column = Current.account.kanban_columns.find(params[:id])
    authorize @column
    @column.destroy!
    head :ok
  end

  private

  def column_params
    params.require(:column).permit(:name, :color, :column_function)
  end
end
