module ChatwootKanban
  module Api
    module V1
      # Inherits Chatwoot's existing API base so we get devise_token_auth,
      # current_user, current_account, pundit, JSON rendering -- all for free.
      # If the host class name ever changes upstream, swap it here in ONE place.
      class BaseController < ::Api::V1::Accounts::BaseController
        include Pundit::Authorization

        rescue_from Pundit::NotAuthorizedError,                with: :render_forbidden
        rescue_from ActiveRecord::RecordNotFound,              with: :render_not_found
        rescue_from ActiveRecord::RecordInvalid,               with: :render_invalid
        rescue_from ChatwootKanban::MoveCardService::WipLimitExceeded, with: :render_wip_blocked

        before_action :ensure_kanban_enabled!

        private

        def ensure_kanban_enabled!
          flag = ChatwootKanban.configuration.feature_flag
          return if flag.nil?
          return if Current.account&.feature_enabled?(flag.to_s)

          render json: { error: 'Kanban feature is not enabled for this account.' }, status: :forbidden
        end

        def render_forbidden(exception)
          render json: { error: exception.message }, status: :forbidden
        end

        def render_not_found(exception)
          render json: { error: exception.message }, status: :not_found
        end

        def render_invalid(exception)
          render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
        end

        def render_wip_blocked(exception)
          render json: { error: exception.message, code: 'wip_limit_exceeded' }, status: :unprocessable_entity
        end
      end
    end
  end
end
