class DeviseOverrides::ConfirmationsController < Devise::ConfirmationsController
  include AuthHelper
  skip_before_action :require_no_authentication, raise: false
  skip_before_action :authenticate_user!, raise: false

  def create
    @confirmable = User.find_by(confirmation_token: params[:confirmation_token])
    return render_confirmation_error if @confirmable.blank?

    if @confirmable.confirm
      render_confirmation_success
    else
      render_confirmation_error
    end
  end

  private

  def render_confirmation_success
    send_auth_headers(@confirmable)
    render partial: 'devise/auth', formats: [:json], locals: { resource: @confirmable }
  end

  def render_confirmation_error
    if @confirmable.blank?
      render json: { message: 'Invalid token', redirect_url: '/' }, status: :unprocessable_entity
    elsif @confirmable.confirmed_at
      render json: { message: 'Already confirmed', redirect_url: '/' }, status: :unprocessable_entity
    else
      render json: { message: 'Failure', redirect_url: '/' }, status: :unprocessable_entity
    end
  end
end
