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
    invitee = appointment.payload['invitee'] || {}
    event = appointment.payload['event'] || {}

    {
      id: appointment.id,
      provider: appointment.provider,
      status: appointment.status,
      scheduling_url: appointment.scheduling_url,
      event_type_name: appointment.event_type_name,
      event_type_uri: appointment.event_type_uri,
      scheduled_at: appointment.scheduled_at&.iso8601,
      end_time: appointment.payload['end_time'],
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
      },
      invitee: {
        name: invitee['name'],
        email: invitee['email'],
        timezone: invitee['timezone'],
        cancel_url: invitee['cancel_url'],
        reschedule_url: invitee['reschedule_url'],
        rescheduled: invitee['rescheduled'],
        no_show: invitee['no_show'],
        payment: invitee['payment'],
        questions_and_answers: invitee['questions_and_answers']
      }.compact,
      event: {
        name: event['name'],
        status: event['status'],
        start_time: event['start_time'],
        end_time: event['end_time'],
        location: event['location'],
        event_type: event['event_type'],
        event_memberships: event['event_memberships'],
        event_guests: event['event_guests'],
        meeting_notes_plain: event['meeting_notes_plain']
      }.compact
    }
  end

  def check_authorization
    authorize Appointment
  end
end
