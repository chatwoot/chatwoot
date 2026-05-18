module ChatwootKanban
  module Api
    module V1
      class CardActivitiesController < BaseController
        def index
          card = ChatwootKanban::Card
                   .joins(column: :board)
                   .where(chatwoot_kanban_boards: { account_id: Current.account.id })
                   .find(params[:kanban_card_id])

          @activities = card.activities.order(created_at: :desc).limit(100)
        end
      end
    end
  end
end
