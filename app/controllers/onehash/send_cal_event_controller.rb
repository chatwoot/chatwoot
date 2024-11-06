# class Onehash::SendCalEventController < ApplicationController
class Onehash::SendCalEventController < Api::V1::Accounts::BaseController
  def send_event_handler
    return render_error('Conversation ID, Account ID, and Event URL are required.') unless valid_params?

    if sent_event
      render json: { message: 'Calendar event sent successfully.' }, status: :ok
    else
      render json: { error: 'Failed to send calendar event.' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def valid_params?
    permitted_params[:conversation_id] && permitted_params[:account_id] && permitted_params[:event_url]
  end

  def sent_event
    cal_event_book = MessageTemplates::Template::CalEvent.new(
      permitted_params[:conversation_id],
      permitted_params[:account_id],
      permitted_params[:event_url]
    )
    cal_event_book.perform
  end

  def render_error(message)
    render json: { error: message }, status: :bad_request
  end

  def permitted_params
    params.permit(:conversation_id, :account_id, :event_url)
  end
end
