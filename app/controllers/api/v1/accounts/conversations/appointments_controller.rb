class Api::V1::Accounts::Conversations::AppointmentsController < Api::V1::Accounts::Conversations::BaseController
  skip_before_action :conversation
  before_action :set_conversation

  def create
    appointment = Appointments::CreateService.new(
      conversation: @conversation,
      user: Current.user,
      event_type_uri: permitted_params[:event_type_uri],
      event_type_name: permitted_params[:event_type_name]
    ).perform

    render json: { success: true, data: appointment_response(appointment) }, status: :created
  rescue StandardError => e
    Rails.logger.error "Appointment creation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def appointment_response(appointment)
    {
      id: appointment.id,
      scheduling_url: appointment.scheduling_url,
      event_type_name: appointment.event_type_name,
      status: appointment.status,
      provider: appointment.provider
    }
  end

  def permitted_params
    params.permit(:event_type_uri, :event_type_name)
  end

  def set_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize Appointment, :create?
  end
end
