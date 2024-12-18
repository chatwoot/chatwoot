class Onehash::SendCalEventConfirmationController < ApplicationController
  # class Onehash::SendCalEventConfirmationController < Api::V1::Widget::BaseController
  def send_confirmation_handler
    return render_error('Message Id and Event payload are required.') unless valid_params?

    if send_confirmation
      render json: { message: 'Calendar event booked successfully.' }, status: :ok
    else
      render json: { error: 'Failed to book calendar event.' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def valid_params?
    permitted_params[:event_payload].present? && permitted_params[:message_id].present?
  end

  def send_confirmation
    event_payload = permitted_params[:event_payload]

    cal_event_book = MessageTemplates::Template::CalEventConfirmation.new(
      permitted_params[:message_id],
      {
        event_scheduled_at: event_payload[:event_scheduled_at].permit(:time, :date, :timezone).to_h,
        event_booker: event_payload[:event_booker],
        event_organizer: event_payload[:event_organizer]
      }
    )
    cal_event_book.perform
  end

  def render_error(message)
    render json: { error: message }, status: :bad_request
  end

  def permitted_params
    params.permit(
      :message_id,
      event_payload: [
        :event_booker,
        :event_organizer,
        { event_scheduled_at: [:time, :date, :timezone] }
      ]
    )
  end
end
