module ChatwootGlpiIntegration
  module Api
    module V1
      class BaseController < ::Api::V1::Accounts::BaseController
        rescue_from ChatwootGlpiIntegration::GlpiClient::Error, with: :render_remote_error
        rescue_from ActiveRecord::RecordNotFound,                with: ->(e) { render json: { error: e.message }, status: :not_found }
        rescue_from ActiveRecord::RecordInvalid,                 with: ->(e) { render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity }

        private

        def render_remote_error(exception)
          render json: { error: exception.message, source: 'glpi' }, status: :bad_gateway
        end
      end
    end
  end
end
