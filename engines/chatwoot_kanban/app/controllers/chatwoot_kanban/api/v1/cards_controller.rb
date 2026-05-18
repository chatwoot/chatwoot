module ChatwootKanban
  module Api
    module V1
      class CardsController < BaseController
        before_action :set_board
        before_action :set_card, only: [:show, :update, :destroy, :unarchive]

        # GET /cards  -- supports filters: q, assignee_id, priority,
        # label_ids[], due_before, due_after, include_archived, page, per_page
        def index
          @cards = filtered_cards
          render :index
        end

        def show
          authorize @card, policy_class: ChatwootKanban::CardPolicy
        end

        def create
          column = @board.columns.find(card_params[:column_id])
          @card = column.cards.new(card_params.except(:column_id).merge(created_by_id: Current.user.id))
          @card.position ||= (column.cards.maximum(:position) || -1) + 1
          authorize @card, policy_class: ChatwootKanban::CardPolicy

          ChatwootKanban::Card.transaction do
            @card.save!
            @card.activities.create!(actor_id: Current.user.id, action: 'created',
                                     payload: { title: @card.title, column_id: column.id })
          end
          broadcast(:card_created, card_id: @card.id, column_id: column.id)
          render :show, status: :created
        end

        def update
          authorize @card, policy_class: ChatwootKanban::CardPolicy
          @card.update!(card_params.except(:column_id))
          @card.activities.create!(actor_id: Current.user.id, action: 'updated',
                                   payload: card_params.except(:column_id))
          broadcast(:card_updated, card_id: @card.id)
          render :show
        end

        def destroy
          authorize @card, policy_class: ChatwootKanban::CardPolicy
          if params[:hard].to_s == 'true'
            @card.destroy!
          else
            @card.archive!
            @card.activities.create!(actor_id: Current.user.id, action: 'archived', payload: {})
          end
          broadcast(:card_deleted, card_id: @card.id)
          head :no_content
        end

        def unarchive
          authorize @card, policy_class: ChatwootKanban::CardPolicy
          @card.unarchive!
          broadcast(:card_updated, card_id: @card.id)
          render :show
        end

        # PATCH /cards/move
        def move
          @card = card_scope.find(params[:card_id])
          authorize @card, policy_class: ChatwootKanban::CardPolicy

          ChatwootKanban::MoveCardService.new(
            card:         @card,
            to_column_id: params[:to_column_id].to_i,
            position:     params[:position].to_i,
            actor:        Current.user
          ).call

          render :show
        end

        private

        def set_board
          @board = ChatwootKanban::Board.where(account_id: Current.account.id).find(params[:kanban_board_id])
        end

        def set_card
          @card = card_scope(include_archived: true).find(params[:id])
        end

        def card_scope(include_archived: false)
          scope = ChatwootKanban::Card.joins(:column).where(chatwoot_kanban_columns: { board_id: @board.id })
          include_archived ? scope : scope.active
        end

        def card_params
          params.require(:card).permit(:column_id, :title, :description, :priority,
                                        :due_at, :assignee_id, :position, :conversation_id,
                                        metadata: {})
        end

        def filtered_cards
          scope = card_scope(include_archived: ActiveModel::Type::Boolean.new.cast(params[:include_archived]))

          if params[:q].present?
            term = "%#{params[:q].to_s.downcase}%"
            scope = scope.where('LOWER(chatwoot_kanban_cards.title) LIKE :q OR LOWER(chatwoot_kanban_cards.description) LIKE :q', q: term)
          end
          scope = scope.where(assignee_id: params[:assignee_id])    if params[:assignee_id].present?
          scope = scope.where(priority: params[:priority])          if params[:priority].present?
          scope = scope.where('due_at < ?', params[:due_before])    if params[:due_before].present?
          scope = scope.where('due_at > ?', params[:due_after])     if params[:due_after].present?

          if (label_ids = Array(params[:label_ids]).compact_blank).any?
            scope = scope.joins(:card_labels).where(chatwoot_kanban_card_labels: { label_id: label_ids }).distinct
          end

          per_page = (params[:per_page] || 100).to_i.clamp(1, 500)
          page     = (params[:page]     || 1).to_i.clamp(1, 10_000)
          scope.order('chatwoot_kanban_columns.position, chatwoot_kanban_cards.position')
               .limit(per_page).offset((page - 1) * per_page)
        end

        def broadcast(event, payload)
          ChatwootKanban::BroadcastService.broadcast(board: @board, event: event, payload: payload)
        end
      end
    end
  end
end
