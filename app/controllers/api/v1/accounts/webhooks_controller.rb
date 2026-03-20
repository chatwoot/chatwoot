class Api::V1::Accounts::WebhooksController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_webhook, only: [:update, :destroy]

  def index
    @webhooks = Current.account.webhooks
  end

  def create
    @webhook = Current.account.webhooks.new(webhook_create_params)
    @webhook.save!
  end

  def update
    @webhook.update!(webhook_update_params)
  end

  def destroy
    @webhook.destroy!
    head :ok
  end

  private

  def webhook_create_params
    params.require(:webhook).permit(:inbox_id, :name, :url, subscriptions: [])
  end

  def webhook_update_params
    params.require(:webhook).permit(:name, subscriptions: [])
  end

  def fetch_webhook
    @webhook = Current.account.webhooks.find(params[:id])
  end
end
