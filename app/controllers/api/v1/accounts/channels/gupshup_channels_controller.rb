
class Api::V1::Accounts::Channels::GupshupChannelsController < Api::V1::Accounts::BaseController
  before_action :authorize_request

  def create
    ActiveRecord::Base.transaction do
      build_inbox
      setup_webhooks
    rescue StandardError => e
      render_could_not_create_error(e.message)
    end
  end

  private

  def authorize_request
    authorize ::Inbox
  end

  def setup_webhooks
    ::Gupshup::WebhookSetupService.new(inbox: @inbox).perform
  end

  def phone_number
    permitted_params[:phone_number]
  end

  def medium
    permitted_params[:medium]
  end

  def build_inbox

    @gupshup_channel = Current.account.gupshups.create!(
      app: permitted_params[:app],
      apikey: permitted_params[:apikey],
      phone_number: phone_number
    )
    puts permitted_params[:app]
    puts permitted_params[:apikey]
    puts phone_number
    puts permitted_params[:name]
    @inbox = Current.account.inboxes.create(
      name: permitted_params[:name],
      channel: @gupshup_channel
    )

  end

  def permitted_params
    params.require(:gupshup_channel).permit(
      :account_id,
      :app,
      :name,
      :apikey,
      :phone_number
    )
  end
end
