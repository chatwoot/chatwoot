class Api::V1::Accounts::Integrations::HooksController < Api::V1::Accounts::BaseController
  DATA_IMPORT_FEATURE = 'data_import'.freeze

  before_action :fetch_hook, except: [:create]
  before_action :ensure_intercom_data_import_feature_enabled, only: [:create, :update, :destroy]
  before_action :reject_intercom_hook_create, only: [:create]
  before_action :check_authorization

  def create
    @hook = Current.account.hooks.create!(permitted_params)
  end

  def update
    return render_active_intercom_import_error if intercom_hook_with_active_import?

    @hook.update!(permitted_params.slice(:status, :settings))
  end

  def process_event
    response = @hook.process_event(params[:event])

    # for cases like an invalid event, or when conversation does not have enough messages
    # for a label suggestion, the response is nil
    if response.nil?
      render json: { message: nil }
    elsif response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: { message: response[:message] }
    end
  end

  def destroy
    blocked = false
    Current.account.with_lock do
      if intercom_hook_with_active_import?
        blocked = true
        next
      end

      @hook.destroy!
    end

    return render_active_intercom_import_error if blocked

    head :ok
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find(params[:id])
  end

  def check_authorization
    authorize(:hook)
  end

  def ensure_intercom_data_import_feature_enabled
    return unless intercom_hook_request?
    return if Current.account.feature_enabled?(DATA_IMPORT_FEATURE)

    raise Pundit::NotAuthorizedError
  end

  def reject_intercom_hook_create
    return unless intercom_hook_request?

    render json: { message: 'Intercom must be connected from the Intercom integration settings.' }, status: :unprocessable_entity
  end

  def intercom_hook_request?
    return @hook.app_id == 'intercom' if @hook.present?

    params[:app_id] == 'intercom' || params.dig(:hook, :app_id) == 'intercom'
  end

  def intercom_hook_with_active_import?
    @hook.app_id == 'intercom' && Current.account.data_imports.exists?(source_provider: 'intercom', status: [:pending, :processing])
  end

  def render_active_intercom_import_error
    render json: { message: 'Intercom cannot be changed while an import is active.' }, status: :unprocessable_entity
  end

  def permitted_params
    params.require(:hook).permit(:app_id, :inbox_id, :status, settings: {})
  end
end
