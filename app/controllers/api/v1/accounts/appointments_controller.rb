class Api::V1::Accounts::AppointmentsController < Api::V1::Accounts::BaseController
  include AppointmentQrGenerator

  skip_before_action :authenticate_user!, only: [:validate_appointment_token]
  skip_before_action :current_account, only: [:validate_appointment_token]
  before_action :appointment, except: [:index, :create, :validate_appointment_token]
  before_action :check_authorization, except: [:validate_appointment_token]

  def index
    @appointments = Current.account.appointments.includes(:contact).order(start_time: :desc)
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

  private

  def appointment
    @appointment ||= Current.account.appointments.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:location, :description, :start_time, :end_time, :assisted)
  end
end
