class Api::V1::Accounts::AppointmentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    appointments = Current.account.appointments
                          .includes(:contact, :conversation, :created_by)
                          .by_status(params[:status])
                          .for_contact(params[:contact_id])
                          .filter_by_conversation(params[:conversation_id])
                          .search(params[:q])
                          .recent
                          .page(params[:page])

    render json: {
      data: appointments.map { |a| appointment_json(a) },
      meta: {
        total: appointments.total_count,
        page: appointments.current_page,
        total_pages: appointments.total_pages,
        per_page: appointments.limit_value
      }
    }
  end

  def show
    appointment = Current.account.appointments
                         .includes(:contact, :conversation, :created_by)
                         .find(params[:id])

    render json: { data: appointment_json(appointment) }
  end

  private

  def appointment_json(appointment)
    {
      id: appointment.id,
      provider: appointment.provider,
      status: appointment.status,
      scheduling_url: appointment.scheduling_url,
      event_type_name: appointment.event_type_name,
      event_type_uri: appointment.event_type_uri,
      scheduled_at: appointment.scheduled_at&.iso8601,
      external_event_id: appointment.external_event_id,
      created_at: appointment.created_at.iso8601,
      updated_at: appointment.updated_at.iso8601,
      contact: {
        id: appointment.contact.id,
        name: appointment.contact.name,
        email: appointment.contact.email,
        phone_number: appointment.contact.phone_number
      },
      conversation: {
        id: appointment.conversation.id,
        display_id: appointment.conversation.display_id
      },
      created_by: {
        id: appointment.created_by.id,
        name: appointment.created_by.name
      }
    }
  end

  def check_authorization
    authorize Appointment
  end
end
