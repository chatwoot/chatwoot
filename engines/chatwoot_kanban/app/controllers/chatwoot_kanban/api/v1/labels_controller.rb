module ChatwootKanban
  module Api
    module V1
      # Account-scoped labels (NOT board-scoped) — same label can be reused across boards.
      class LabelsController < BaseController
        before_action :set_label, only: [:update, :destroy]

        def index
          @labels = ChatwootKanban::Label.where(account_id: Current.account.id).order(:name)
        end

        def create
          @label = ChatwootKanban::Label.create!(label_params.merge(account_id: Current.account.id))
          render :show, status: :created
        end

        def update
          @label.update!(label_params)
          render :show
        end

        def destroy
          @label.destroy!
          head :no_content
        end

        # POST /cards/:card_id/labels — assign existing label to card
        def assign
          card = ChatwootKanban::Card.joins(column: :board)
                                     .where(chatwoot_kanban_boards: { account_id: Current.account.id })
                                     .find(params[:kanban_card_id])
          label = ChatwootKanban::Label.where(account_id: Current.account.id).find(params[:label_id])
          ChatwootKanban::CardLabel.find_or_create_by!(card: card, label: label)
          ChatwootKanban::BroadcastService.broadcast(
            board: card.board, event: :card_updated, payload: { card_id: card.id }
          )
          head :no_content
        end

        # DELETE /cards/:card_id/labels/:label_id — remove
        def unassign
          card = ChatwootKanban::Card.joins(column: :board)
                                     .where(chatwoot_kanban_boards: { account_id: Current.account.id })
                                     .find(params[:kanban_card_id])
          ChatwootKanban::CardLabel.where(card_id: card.id, label_id: params[:label_id]).destroy_all
          ChatwootKanban::BroadcastService.broadcast(
            board: card.board, event: :card_updated, payload: { card_id: card.id }
          )
          head :no_content
        end

        private

        def set_label
          @label = ChatwootKanban::Label.where(account_id: Current.account.id).find(params[:id])
        end

        def label_params
          params.require(:label).permit(:name, :color)
        end
      end
    end
  end
end
