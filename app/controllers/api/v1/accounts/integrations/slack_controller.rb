class Api::V1::Accounts::Integrations::SlackController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, only: [:update, :destroy]

  def create
    builder = Integrations::Slack::HookBuilder.new(
      account: current_account,
      code: params[:code],
      inbox_id: params[:inbox_id]
    )

    @hook = builder.perform

    render json: @hook
  end

  def update
    builder = Integrations::Slack::ChannelBuilder.new(
      hook: @hook, channel: params[:channel]
    )
    builder.perform

    render json: @hook
  end

  def destroy
    @hook.destroy

    head :ok
  end

  private

  def fetch_hook
    @hook = Integrations::Hook.find(params[:id])
  end
end
