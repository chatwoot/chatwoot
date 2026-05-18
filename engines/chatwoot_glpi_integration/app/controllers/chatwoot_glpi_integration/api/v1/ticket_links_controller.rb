module ChatwootGlpiIntegration
  module Api
    module V1
      class TicketLinksController < BaseController
        before_action :set_connection
        before_action :set_link, only: [:show, :destroy, :sync]

        def index
          scope = TicketLink.for_account(Current.account.id)
          scope = scope.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
          scope = scope.where(kanban_card_id:  params[:kanban_card_id])  if params[:kanban_card_id].present?
          @links = scope.order(created_at: :desc).limit(200)
          render :index
        end

        def show
          render :show
        end

        # POST /glpi/tickets
        # body: { conversation_id:, kanban_card_id:, override: {...} }
        def create
          conversation = if params[:conversation_id].present?
                           ::Conversation.find_by(account_id: Current.account.id, id: params[:conversation_id])
                         end
          card         = if params[:kanban_card_id].present?
                           ChatwootKanban::Card.joins(column: :board)
                                              .where(chatwoot_kanban_boards: { account_id: Current.account.id })
                                              .find_by(id: params[:kanban_card_id])
                         end

          @link = CreateTicketService.new(
            connection:   @connection,
            conversation: conversation,
            kanban_card:  card,
            actor:        Current.user,
            override:     (params[:override] || {}).to_unsafe_h.symbolize_keys
          ).call
          render :show, status: :created
        end

        def destroy
          @link.destroy!
          head :no_content
        end

        # POST /glpi/tickets/:id/sync
        def sync
          SyncTicketJob.perform_later(@link.id)
          head :accepted
        end

        # POST /glpi/tickets/reconcile_all
        def reconcile_all
          ReconcileAllJob.perform_later(Current.account.id)
          head :accepted
        end

        private

        def set_connection
          @connection = Connection.find_by!(account_id: Current.account.id, active: true)
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'GLPI connection not configured' }, status: :unprocessable_entity
        end

        def set_link
          @link = TicketLink.for_account(Current.account.id).find(params[:id])
        end
      end
    end
  end
end
