class Api::V1::Accounts::Channels::TwilioChannelsController < Api::BaseController
  before_action :authorize_request

  def create
    authenticate_twilio
    build_inbox
    setup_webhooks
  rescue Twilio::REST::TwilioError => e
    render_could_not_create_error(e.message)
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  private

  def authorize_request
    authorize ::Inbox
  end

  def authenticate_twilio
    client = Twilio::REST::Client.new(permitted_params[:account_sid], permitted_params[:auth_token])
    client.messages.list(limit: 1)
  end

  def setup_webhooks
    ::Twilio::WebhookSetupService.new(inbox: @inbox).perform
  end

  def build_inbox
    ActiveRecord::Base.transaction do
      twilio_sms = current_account.twilio_sms.create(
        account_sid: permitted_params[:account_sid],
        auth_token: permitted_params[:auth_token],
        phone_number: permitted_params[:phone_number]
      )
      @inbox = current_account.inboxes.create(
        name: permitted_params[:name],
        channel: twilio_sms
      )
    rescue StandardError => e
      render_could_not_create_error(e.message)
    end
  end

  def permitted_params
    params.require(:twilio_channel).permit(
      :account_id, :phone_number, :account_sid, :auth_token, :name
    )
  end
end
