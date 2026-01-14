class Api::V1::Accounts::AppointmentsController < Api::V1::Accounts::BaseController
  include AppointmentQrGenerator
  include FrontendUrlsHelper
  include Sift

  sort_on :start_time, type: :datetime
  sort_on :end_time, type: :datetime
  sort_on :location, type: :string
  sort_on :created_at, type: :datetime

  RESULTS_PER_PAGE = 15

  skip_before_action :authenticate_user!, only: [:validate_appointment_token, :show_qr]
  skip_before_action :current_account, only: [:validate_appointment_token, :show_qr]
  before_action :check_authorization, except: [:validate_appointment_token, :show_qr]
  before_action :set_current_page, only: [:index, :search, :filter]
  before_action :appointment, only: [:show, :update, :destroy]

  def index
    appointments = Current.account.appointments.includes(:contact)
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

  def create
    contact = Current.account.contacts.find(params[:contact_id])
    @appointment = contact.appointments.build(appointment_params)
    @appointment.account = Current.account
    @appointment.save!

    generate_qr_code_for_appointment(@appointment)
  end

  def update
    @appointment.update!(appointment_params)
  end

  def destroy
    @appointment.destroy!
    head :ok
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
  end

  def appointment_params
    params.require(:appointment).permit(:location, :description, :start_time, :end_time, :assisted)
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_appointments(appointments)
    filtrate(appointments)
      .includes(:contact)
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
end
