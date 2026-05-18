module ChatwootKanban
  module Api
    module V1
      class CommentsController < BaseController
        before_action :set_card

        def index
          @comments = @card.comments.order(created_at: :desc)
        end

        def create
          @comment = @card.comments.create!(content: comment_params[:content], author_id: Current.user.id)
          @card.activities.create!(actor_id: Current.user.id, action: 'commented',
                                   payload: { comment_id: @comment.id, mentions: @comment.mentioned_user_ids })
          ChatwootKanban::BroadcastService.broadcast(
            board: @card.board, event: :comment_created,
            payload: { card_id: @card.id, comment_id: @comment.id }
          )
          render :show, status: :created
        end

        def destroy
          @comment = @card.comments.find(params[:id])
          authorize_owner!(@comment)
          @comment.destroy!
          ChatwootKanban::BroadcastService.broadcast(
            board: @card.board, event: :comment_deleted,
            payload: { card_id: @card.id, comment_id: @comment.id }
          )
          head :no_content
        end

        private

        def set_card
          @card = ChatwootKanban::Card
                    .joins(column: :board)
                    .where(chatwoot_kanban_boards: { account_id: Current.account.id })
                    .find(params[:kanban_card_id])
          authorize @card, :show?, policy_class: ChatwootKanban::CardPolicy
        end

        def authorize_owner!(comment)
          return if comment.author_id == Current.user.id

          au = Current.user.account_users.find_by(account_id: @card.board.account_id)
          raise Pundit::NotAuthorizedError unless au&.administrator?
        end

        def comment_params
          params.require(:comment).permit(:content)
        end
      end
    end
  end
end
