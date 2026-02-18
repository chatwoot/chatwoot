class Api::V1::Accounts::AppointmentsController < Api::V1::Accounts::BaseController
  include AppointmentQrGenerator
  include FrontendUrlsHelper
  include Sift

  sort_on :scheduled_at, type: :datetime
  sort_on :ended_at, type: :datetime
  sort_on :location, type: :string
  sort_on :created_at, type: :datetime

  RESULTS_PER_PAGE = 15

  skip_before_action :authenticate_user!, only: [:validate_appointment_token, :show_qr]
  skip_before_action :current_account, only: [:validate_appointment_token, :show_qr]
  before_action :check_authorization, except: [:validate_appointment_token, :show_qr]
  before_action :set_current_page, only: [:index, :search, :filter]
  before_action :appointment, only: [:show, :update, :destroy, :start, :complete, :cancel, :mark_no_show]

  # GET /api/v1/accounts/:account_id/appointments/available_types
  # Returns the appointment types enabled for this account
  def available_types
    types = Current.account.available_appointment_types.map do |type|
      {
        key: type,
        label: I18n.t("appointments.types.#{type}", locale: Current.account.locale, default: type.humanize)
      }
    end
    render json: { appointment_types: types }, status: :ok
  end

  def index
    appointments = Current.account.appointments.includes(:contact, :owner)
    # Supervisor only sees appointments of contacts with conversations assigned to themselves or subordinates
    appointments = filter_appointments_for_supervisor(appointments) if Current.account_user&.supervisor?
    @appointments = fetch_appointments(appointments)
    @appointments_count = @appointments.total_count
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    appointments = Current.account.appointments.left_joins(:contact).where(
      'contacts.name ILIKE :search OR contacts.email ILIKE :search OR contacts.phone_number ILIKE :search
       OR appointments.location ILIKE :search OR appointments.description ILIKE :search',
      search: "%#{params[:q].strip}%"
    )
    # Supervisor only sees appointments of contacts with conversations assigned to themselves or subordinates
    appointments = filter_appointments_for_supervisor(appointments) if Current.account_user&.supervisor?
    @appointments = fetch_appointments(appointments)
    @appointments_count = @appointments.total_count
  end

  def filter
    result = ::Appointments::FilterService.new(Current.account, Current.user, params.permit!).perform
    appointments = result[:appointments]
    @appointments_count = result[:count]
    @appointments = fetch_appointments(appointments)
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
  end

  def show; end

  # POST /api/v1/accounts/:account_id/appointments
  # Creates a new appointment for a contact.
  # Required params: contact_id, scheduled_at, appointment_type, owner_id
  # Type-specific required: phone_number (phone_call), meeting_url (digital_meeting), location (physical_visit)
  def create
    contact = Current.account.contacts.find_by(id: params[:contact_id])
    return render_error('Contact not found', :not_found) unless contact

    # Validar que el tipo de cita esté habilitado
    appointment_type = appointment_params[:appointment_type]
    if appointment_type.present? && !Current.account.appointment_type_enabled?(appointment_type)
      return render_error("Appointment type '#{appointment_type}' is not enabled for this account", :unprocessable_entity)
    end

    @appointment = contact.appointments.build(appointment_params)
    @appointment.account = Current.account

    if @appointment.save
      generate_qr_code_for_appointment(@appointment)
      render :show, status: :created
    else
      render_validation_errors(@appointment.errors)
    end
  rescue ArgumentError => e
    # Captura errores de enum inválido (appointment_type, status)
    render_error("Invalid value: #{e.message}", :unprocessable_entity)
  end

  # PATCH /api/v1/accounts/:account_id/appointments/:id
  # Updates an appointment. Cannot change appointment_type after creation.
  def update
    # No permitir cambiar el tipo después de crear (lógica de negocio)
    if appointment_params[:appointment_type].present? && appointment_params[:appointment_type] != @appointment.appointment_type
      return render_error('Cannot change appointment type after creation', :unprocessable_entity)
    end

    if @appointment.update(appointment_params)
      render :show
    else
      render_validation_errors(@appointment.errors)
    end
  rescue ArgumentError => e
    render_error("Invalid value: #{e.message}", :unprocessable_entity)
  end

  # DELETE /api/v1/accounts/:account_id/appointments/:id
  # Soft-deletes an appointment (uses discard gem).
  def destroy
    @appointment.discard
    head :no_content
  end

  # POST /api/v1/accounts/:account_id/appointments/:id/start
  # Transitions appointment to in_progress status.
  def start
    if @appointment.scheduled?
      @appointment.start!
      render :show
    else
      render_error("Cannot start appointment. Current status: #{@appointment.status}", :unprocessable_entity)
    end
  rescue StandardError => e
    render_error("Failed to start appointment: #{e.message}", :unprocessable_entity)
  end

  # POST /api/v1/accounts/:account_id/appointments/:id/complete
  # Transitions appointment to completed status and records ended_at timestamp.
  def complete
    if @appointment.in_progress? || @appointment.scheduled?
      @appointment.complete!
      render :show
    else
      render_error("Cannot complete appointment. Current status: #{@appointment.status}", :unprocessable_entity)
    end
  rescue StandardError => e
    render_error("Failed to complete appointment: #{e.message}", :unprocessable_entity)
  end

  # POST /api/v1/accounts/:account_id/appointments/:id/cancel
  # Transitions appointment to cancelled status.
  def cancel
    if @appointment.scheduled?
      @appointment.cancel!
      render :show
    else
      render_error("Cannot cancel appointment. Current status: #{@appointment.status}", :unprocessable_entity)
    end
  rescue StandardError => e
    render_error("Failed to cancel appointment: #{e.message}", :unprocessable_entity)
  end

  # POST /api/v1/accounts/:account_id/appointments/:id/mark_no_show
  # Marks appointment as no_show when contact doesn't attend.
  def mark_no_show
    if @appointment.scheduled? || @appointment.in_progress?
      @appointment.mark_no_show!
      render :show
    else
      render_error("Cannot mark as no-show. Current status: #{@appointment.status}", :unprocessable_entity)
    end
  rescue StandardError => e
    render_error("Failed to mark no-show: #{e.message}", :unprocessable_entity)
  end

  def validate_appointment_token
    appointment = Appointment.find_by(access_token: params[:token])

    if appointment
      render json: { valid: true, contact_id: appointment.contact_id }, status: :ok
    else
      render json: { valid: false }, status: :unauthorized
    end
  end

  def show_qr
    appointment = Appointment.find_by(id: params[:id])

    if appointment&.qr_code.present?
      redirect_to url_for(appointment.qr_code)
    elsif appointment
      redirect_to frontend_url("accounts/#{appointment.account.id}/contacts/appointments", error: 'appointment-not-found')
    else
      render json: { valid: false }, status: :unauthorized
    end
  end

  private

  def appointment
    @appointment ||= Current.account.appointments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Appointment not found', :not_found)
  end

  def appointment_params
    params.require(:appointment).permit(
      :location,
      :description,
      :scheduled_at,
      :ended_at,
      :appointment_type,
      :status,
      :owner_id,
      :inbox_id,
      :conversation_id,
      :phone_number,
      :meeting_url,
      :assisted,
      participants: [:agent_ids, :contact_ids],
      additional_attributes: {}
    )
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_appointments(appointments)
    filtrate(appointments)
      .includes(:contact, :owner)
      .kept # exclude discarded
      .page(@current_page)
      .per(RESULTS_PER_PAGE)
  end

  def filter_appointments_for_supervisor(appointments)
    assignee_ids = Current.account_user.all_subordinate_user_ids + [Current.user.id]
    contact_ids = Current.account.conversations
                         .where(assignee_id: assignee_ids)
                         .pluck(:contact_id)
                         .uniq
    appointments.where(contact_id: contact_ids)
  end

  def render_validation_errors(errors)
    render json: {
      message: 'Validation failed',
      errors: errors.full_messages,
      details: errors.messages
    }, status: :unprocessable_entity
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
