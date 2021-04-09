class Api::V1::Accounts::Integrations::SlackController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, only: [:update, :destroy]

  def create
    ActiveRecord::Base.transaction do
      builder = Integrations::Slack::HookBuilder.new(
        account: Current.account,
        code: params[:code],
        inbox_id: params[:inbox_id]
      )
      @hook = builder.perform

      if @hook.reference_id.present?
        join_slack_channel
      else
        create_chatwoot_slack_channel
      end
    end
  end

  def update
    create_chatwoot_slack_channel
    render json: @hook
  end

  def destroy
    @hook.destroy

    head :ok
  end

  private

  def fetch_hook
    @hook = Integrations::Hook.where(account: Current.account).find_by(app_id: 'slack')
  end

  def create_chatwoot_slack_channel
    channel = params[:channel] || 'customer-conversations'
    builder = Integrations::Slack::ChannelBuilder.new(
      hook: @hook, channel: channel
    )
    builder.perform
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: @hook.access_token)
  end

  def join_slack_channel
    slack_client.conversations_join(channel: @hook.reference_id)
  end
end
