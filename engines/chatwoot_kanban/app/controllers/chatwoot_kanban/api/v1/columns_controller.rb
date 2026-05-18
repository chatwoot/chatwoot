module ChatwootKanban
  module Api
    module V1
      class ColumnsController < BaseController
        before_action :set_board
        before_action :set_column, only: [:show, :update, :destroy]

        def index
          @columns = @board.columns.ordered
          authorize @columns, :index?, policy_class: ChatwootKanban::ColumnPolicy
        end

        def show
          authorize @column, policy_class: ChatwootKanban::ColumnPolicy
        end

        def create
          @column = @board.columns.new(column_params)
          @column.position ||= @board.columns.maximum(:position).to_i + 1
          authorize @column, policy_class: ChatwootKanban::ColumnPolicy
          @column.save!
          render :show, status: :created
        end

        def update
          authorize @column, policy_class: ChatwootKanban::ColumnPolicy
          @column.update!(column_params)
          render :show
        end

        def destroy
          authorize @column, policy_class: ChatwootKanban::ColumnPolicy
          @column.destroy!
          head :no_content
        end

        # PATCH /columns/reorder  body: { order: [col_id, col_id, col_id] }
        def reorder
          ids = Array(params[:order]).map(&:to_i)
          authorize @board.columns.first || @board.columns.build, :reorder?, policy_class: ChatwootKanban::ColumnPolicy

          ChatwootKanban::Column.transaction do
            ids.each_with_index do |column_id, idx|
              @board.columns.where(id: column_id).update_all(position: idx)
            end
          end
          @columns = @board.columns.ordered
          render :index
        end

        private

        def set_board
          @board = ChatwootKanban::Board.where(account_id: Current.account.id).find(params[:kanban_board_id])
        end

        def set_column
          @column = @board.columns.find(params[:id])
        end

        def column_params
          params.require(:column).permit(:name, :position, :color, :wip_limit)
        end
      end
    end
  end
end
