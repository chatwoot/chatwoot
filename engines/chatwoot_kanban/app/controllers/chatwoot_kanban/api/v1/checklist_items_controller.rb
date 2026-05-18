module ChatwootKanban
  module Api
    module V1
      class ChecklistItemsController < BaseController
        before_action :set_card
        before_action :set_item, only: [:update, :destroy, :toggle]

        def index
          @items = @card.checklist_items
        end

        def create
          @item = @card.checklist_items.create!(
            title: item_params[:title],
            position: (@card.checklist_items.maximum(:position) || -1) + 1
          )
          broadcast(:checklist_item_created)
          render :show, status: :created
        end

        def update
          @item.update!(item_params)
          broadcast(:checklist_item_updated)
          render :show
        end

        def destroy
          @item.destroy!
          broadcast(:checklist_item_deleted)
          head :no_content
        end

        def toggle
          @item.update!(
            completed: !@item.completed,
            completed_by_id: !@item.completed ? Current.user.id : nil
          )
          broadcast(:checklist_item_toggled)
          render :show
        end

        private

        def set_card
          @card = ChatwootKanban::Card
                    .joins(column: :board)
                    .where(chatwoot_kanban_boards: { account_id: Current.account.id })
                    .find(params[:kanban_card_id])
          authorize @card, :show?, policy_class: ChatwootKanban::CardPolicy
        end

        def set_item
          @item = @card.checklist_items.find(params[:id])
        end

        def item_params
          params.require(:checklist_item).permit(:title, :position, :completed)
        end

        def broadcast(event)
          ChatwootKanban::BroadcastService.broadcast(
            board: @card.board, event: event,
            payload: { card_id: @card.id, item_id: @item&.id }
          )
        end
      end
    end
  end
end
