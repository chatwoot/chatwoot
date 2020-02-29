class Api::V1::Account::WebhooksController < Api::BaseController
  before_action :check_authorization
  before_action :fetch_webhook, only: [:update, :destroy]

  def index
    @webhooks = current_account.webhooks
  end

  def create
    @webhook = current_account.webhooks.new(webhook_params)
    @webhook.save!
  end

  def update
    @webhook.update!(webhook_params)
  end

  def destroy
    @webhook.destroy
    head :ok
  end

  private

  def webhook_params
    params.require(:webhook).permit(:inbox_id, :url)
  end

  def fetch_webhook
    @webhook = current_account.webhooks.find(params[:id])
  end

  def check_authorization
    authorize(Webhook)
  end
end
