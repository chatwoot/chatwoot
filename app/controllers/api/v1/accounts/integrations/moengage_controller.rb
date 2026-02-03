class Api::V1::Accounts::Integrations::MoengageController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_hook, only: [:show, :update, :destroy, :regenerate_token]

  rescue_from ArgumentError, with: :render_argument_error

  def show
    render json: hook_response(@hook)
  end

  def create
    @hook = Integrations::Moengage::HookBuilder.new(
      account: Current.account,
      params: hook_params
    ).perform

    render json: hook_response(@hook), status: :created
  end

  def update
    @hook.update!(settings: merged_settings)
    render json: hook_response(@hook)
  end

  def destroy
    @hook.destroy!
    head :ok
  end

  def regenerate_token
    new_token = SecureRandom.urlsafe_base64(32)
    @hook.settings['webhook_token'] = new_token
    @hook.save!

    render json: hook_response(@hook)
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'moengage')
  end

  def hook_params
    params.require(:hook).permit(
      settings: [
        :workspace_id,
        :data_api_key,
        :data_center,
        :webhook_secret,
        :default_inbox_id,
        :auto_create_contact,
        :enable_ai_response,
        :ai_agent_id
      ]
    )
  end

  def merged_settings
    @hook.settings.merge(hook_params[:settings].to_h.stringify_keys)
  end

  def hook_response(hook)
    {
      id: hook.id,
      app_id: hook.app_id,
      status: hook.status,
      settings: hook.settings.except('data_api_key', 'webhook_secret'),
      webhook_url: webhook_url(hook)
    }
  end

  def webhook_url(hook)
    token = hook.settings['webhook_token']
    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/webhooks/moengage/#{token}"
  end

  def render_argument_error(exception)
    render json: { error: exception.message }, status: :unprocessable_entity
  end
end
