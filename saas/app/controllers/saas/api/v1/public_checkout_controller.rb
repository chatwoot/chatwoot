# frozen_string_literal: true

class Saas::Api::V1::PublicCheckoutController < ActionController::API
  def create
    plan = Saas::Plan.active.find_by!(stripe_price_id: params[:stripe_price_id])
    account, = find_or_create_account
    session = Saas::StripeService.create_checkout_session(account, plan, success_url: landing_success_url)

    render json: { redirect_url: session.url }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Plano nao encontrado' }, status: :not_found
  rescue CustomExceptions::Account::UserExists
    # User already exists — find their account and create checkout
    user = User.find_by!(email: params[:email])
    account = user.accounts.first
    plan = Saas::Plan.active.find_by!(stripe_price_id: params[:stripe_price_id])
    session = Saas::StripeService.create_checkout_session(account, plan, success_url: landing_success_url)
    render json: { redirect_url: session.url }
  rescue StandardError => e
    Rails.logger.error("[PublicCheckout] #{e.class}: #{e.message}")
    render json: { error: 'Erro ao processar checkout. Tente novamente.' }, status: :unprocessable_entity
  end

  private

  def find_or_create_account
    # Password must have: 1 uppercase, 1 lowercase, 1 number, 1 special char
    password = "#{SecureRandom.alphanumeric(12)}Aa1#"
    account_name = params[:company].presence || params[:name].presence || params[:email].split('@').first
    builder = AccountBuilder.new(
      account_name: account_name,
      email: params[:email],
      user_full_name: params[:name],
      user_password: password,
      confirmed: true
    )
    user, account = builder.perform

    # Generate password reset token so the user can set their password
    raw_token = user.send(:set_reset_password_token)
    account.update_column(:custom_attributes, (account.custom_attributes || {}).merge('reset_token' => raw_token))

    # Send welcome email synchronously after token is set
    Saas::BillingMailer.welcome(account).deliver_now

    [account, user]
  end

  def landing_success_url
    ENV.fetch('LANDING_PAGE_URL', 'https://lp.airys.com.br') + '/obrigado'
  end
end
