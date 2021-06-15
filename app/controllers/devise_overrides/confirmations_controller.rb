class DeviseOverrides::ConfirmationsController < Devise::ConfirmationsController
  include AuthHelper
  skip_before_action :require_no_authentication, raise: false
  skip_before_action :authenticate_user!, raise: false

  def create
    @confirmable = User.find_by(confirmation_token: params[:confirmation_token])
    render_confirmation_success and return if @confirmable&.confirm

    render_confirmation_error
  end

  private

  def render_confirmation_success
    send_auth_headers(@confirmable)
    render partial: 'devise/auth.json', locals: { resource: @confirmable }
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

  def create_reset_token_link(user)
    raw, enc = Devise.token_generator.generate(user.class, :reset_password_token)
    user.reset_password_token   = enc
    user.reset_password_sent_at = Time.now.utc
    user.save(validate: false)
    "/app/auth/password/edit?config=default&redirect_url=&reset_password_token=#{raw}"
  end
end
