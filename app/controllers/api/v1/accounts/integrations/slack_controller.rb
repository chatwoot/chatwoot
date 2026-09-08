class Api::V1::Accounts::Integrations::SlackController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_hook, only: [:update, :destroy, :list_all_channels]

  def list_all_channels
    @channels = channel_builder.fetch_channels
  end

  def create
    hook_builder = Integrations::Slack::HookBuilder.new(
      account: Current.account,
      code: params[:code],
      inbox_id: params[:inbox_id]
    )
    @hook = hook_builder.perform
  end

  def update
    return update_message_mode if permitted_params[:message_mode].present?

    @hook = channel_builder.update(permitted_params[:reference_id])
    render json: { error: I18n.t('errors.slack.invalid_channel_id') }, status: :unprocessable_entity if @hook.blank?
  end

  def destroy
    @hook.destroy!
    head :ok
  end

  private

  def fetch_hook
    @hook = Integrations::Hook.where(account: Current.account).find_by(app_id: 'slack')
  end

  def channel_builder
    Integrations::Slack::ChannelBuilder.new(hook: @hook)
  end

  def update_message_mode
    @hook.update!(settings: @hook.settings.merge('message_mode' => permitted_params[:message_mode]))
  end

  def permitted_params
    params.permit(:reference_id, :message_mode)
  end
end
