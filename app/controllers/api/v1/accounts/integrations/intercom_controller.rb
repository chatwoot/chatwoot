class Api::V1::Accounts::Integrations::IntercomController < Api::V1::Accounts::BaseController
  DATA_IMPORT_FEATURE = 'data_import'.freeze

  before_action :ensure_data_import_feature_enabled
  before_action :check_authorization

  def show
    @hook = Current.account.hooks.enabled.find_by(app_id: 'intercom')
  end

  def create
    @hook = DataImports::Intercom::ConnectionService.new(
      account: Current.account,
      access_token: params[:access_token]
    ).perform
  rescue DataImports::Intercom::Client::AuthenticationError, DataImports::Intercom::Client::Error, ArgumentError => e
    render json: { message: e.message }, status: :unprocessable_entity
  end

  def destroy
    blocked = false
    Current.account.with_lock do
      if active_intercom_import?
        blocked = true
        next
      end

      Current.account.hooks.find_by(app_id: 'intercom')&.destroy!
    end

    if blocked
      render json: { message: 'Intercom cannot be disconnected while an import is active.' }, status: :unprocessable_entity
      return
    end

    head :ok
  end

  private

  def ensure_data_import_feature_enabled
    raise Pundit::NotAuthorizedError unless Current.account.feature_enabled?(DATA_IMPORT_FEATURE)
  end

  def check_authorization
    authorize(:hook)
  end

  def active_intercom_import?
    Current.account.data_imports.exists?(source_provider: 'intercom', status: [:pending, :processing])
  end
end
