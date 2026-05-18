module ChatwootKanban
  module Api
    module V1
      class BoardsController < BaseController
        before_action :set_board, only: [:show, :update, :destroy, :duplicate]

        def index
          @boards = ChatwootKanban::Board
                      .where(account_id: Current.account.id)
                      .active
                      .order(created_at: :desc)
        end

        def show
          authorize @board, policy_class: ChatwootKanban::BoardPolicy
        end

        def create
          @board = ChatwootKanban::Board.new(board_params.merge(
            account_id:    Current.account.id,
            created_by_id: Current.user.id
          ))
          authorize @board, policy_class: ChatwootKanban::BoardPolicy
          @board.save!
          render :show, status: :created
        end

        def update
          authorize @board, policy_class: ChatwootKanban::BoardPolicy
          @board.update!(board_params)
          render :show
        end

        def destroy
          authorize @board, policy_class: ChatwootKanban::BoardPolicy
          @board.archive!
          head :no_content
        end

        def duplicate
          authorize @board, policy_class: ChatwootKanban::BoardPolicy
          @board = ChatwootKanban::DuplicateBoardService.new(source: @board, user: Current.user).call
          render :show, status: :created
        end

        private

        def set_board
          @board = ChatwootKanban::Board.where(account_id: Current.account.id).find(params[:id])
        end

        def board_params
          params.require(:board).permit(:name, :description, settings: {})
        end
      end
    end
  end
end
