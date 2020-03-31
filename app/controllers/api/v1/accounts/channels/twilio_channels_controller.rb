class Api::V1::Accounts::Channels::TwilioChannelsController < Api::BaseController
  def create
    authenticate_twilio
    build_inbox
  rescue Twilio::REST::TwilioError => e
    render_could_not_create_error(e.message)
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  private

  def authenticate_twilio
    client = Twilio::REST::Client.new(permitted_params[:account_sid], permitted_params[:auth_token])
    client.messages.list(limit: 1)
  end

  def build_inbox
    ActiveRecord::Base.transaction do
      twilio_sms = current_account.twilio_sms.create(
        account_sid: permitted_params[:account_sid],
        auth_token: permitted_params[:auth_token],
        phone_number: permitted_params[:phone_number]
      )
      @inbox = current_account.inboxes.create(
        name: permitted_params[:phone_number],
        channel: twilio_sms
      )
    rescue StandardError => e
      Rails.logger e
    end
  end

  def permitted_params
    params.permit(:account_id, :phone_number, :account_sid, :auth_token)
  end
end
