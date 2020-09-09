class DeviseOverrides::ConfirmationsController < Devise::ConfirmationsController
  skip_before_action :require_no_authentication, raise: false
  skip_before_action :authenticate_user!, raise: false

  def create
    @confirmable = User.find_by(confirmation_token: params[:confirmation_token])
    if @confirmable
      if @confirmable.confirm || (@confirmable.confirmed_at && @confirmable.reset_password_token)
        # confirmed now or already confirmed but quit before setting a password
        render json: { "message": 'Success', "redirect_url": create_reset_token_link(@confirmable) }, status: :ok
      elsif @confirmable.confirmed_at
        render json: { "message": 'Already confirmed', "redirect_url": '/' }, status: 422
      else
        render json: { "message": 'Failure', "redirect_url": '/' }, status: 422
      end
    else
      render json: { "message": 'Invalid token', "redirect_url": '/' }, status: 422
    end
  end

  protected

  def create_reset_token_link(user)
    raw, enc = Devise.token_generator.generate(user.class, :reset_password_token)
    user.reset_password_token   = enc
    user.reset_password_sent_at = Time.now.utc
    user.save(validate: false)
    "/app/auth/password/edit?config=default&redirect_url=&reset_password_token=#{raw}"
  end
end
