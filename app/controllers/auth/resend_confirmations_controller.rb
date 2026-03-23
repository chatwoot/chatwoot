class Auth::ResendConfirmationsController < ActionController::API
  def create
    return head(:ok) unless ChatwootCaptcha.new(params[:h_captcha_client_response]).valid?

    user = User.from_email(params[:email]&.strip&.downcase)
    user&.send_confirmation_instructions unless user&.confirmed?
    head :ok
  end
end
