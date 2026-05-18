module ChatwootGlpiIntegration
  module Api
    module V1
      class ConnectionsController < BaseController
        before_action :require_administrator!
        before_action :set_connection, only: [:show, :update, :destroy, :test]

        def show
          return render json: { data: nil } if @connection.nil?

          render :show
        end

        def create
          @connection = Connection.new(connection_params.merge(account_id: Current.account.id))
          @connection.save!
          render :show, status: :created
        end

        def update
          @connection.update!(connection_params)
          render :show
        end

        def destroy
          @connection&.destroy
          head :no_content
        end

        # POST /glpi/connection/test
        def test
          return render json: { ok: false, error: 'no connection configured' }, status: :unprocessable_entity if @connection.nil?

          GlpiClient.new(@connection).ping
          render json: { ok: true, handshaked_at: @connection.last_handshake_at }
        rescue GlpiClient::Error => e
          render json: { ok: false, error: e.message }, status: :bad_gateway
        end

        private

        def set_connection
          @connection = Connection.find_by(account_id: Current.account.id)
        end

        def connection_params
          params.require(:connection).permit(
            :base_url, :api_path, :client_id, :client_secret, :scope,
            :default_entity_id, :default_itil_category_id, :default_request_type_id,
            :webhook_secret, :active
          )
        end

        def require_administrator!
          au = Current.user.account_users.find_by(account_id: Current.account.id)
          return if au&.administrator?

          render json: { error: 'Administrator required' }, status: :forbidden
        end
      end
    end
  end
end
