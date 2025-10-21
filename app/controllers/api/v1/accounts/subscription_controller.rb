class Api::V1::Accounts::SubscriptionController < ApplicationController
  before_action :set_current_user
  before_action :check_authorization

  # POST /api/v1/accounts/:account_id/subscription/create_checkout_session
  def create_checkout_session
    tier = params[:tier]&.to_sym

    unless %i[professional premium].include?(tier)
      return render json: { error: 'Invalid tier. Must be professional or premium' }, status: :unprocessable_entity
    end

    price_id = @account.stripe_price_id_for_tier(tier)

    return render json: { error: 'No price configured for this tier' }, status: :unprocessable_entity unless price_id

    begin
      checkout_session = Stripe::Checkout::Session.create(
        customer_email: @user.email,
        line_items: [{
          price: price_id,
          quantity: 1
        }],
        mode: 'subscription',
        success_url: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/accounts/#{@account.id}/settings?subscription_success=true",
        cancel_url: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/accounts/#{@account.id}/subscription/paywall?subscription_cancelled=true",
        metadata: {
          account_id: @account.id,
          tier: tier
        }
      )

      render json: { checkout_url: checkout_session.url }, status: :ok
    rescue Stripe::StripeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/accounts/:account_id/subscription/create_portal_session
  def create_portal_session
    stripe_customer_id = @account.custom_attributes&.dig('stripe_customer_id')

    return render json: { error: 'No active subscription found' }, status: :unprocessable_entity unless stripe_customer_id

    begin
      portal_session = Stripe::BillingPortal::Session.create(
        customer: stripe_customer_id,
        return_url: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/accounts/#{@account.id}/settings/billing"
      )

      render json: { portal_url: portal_session.url }, status: :ok
    rescue Stripe::StripeError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def set_current_user
    # Get user from Devise session
    @user = warden.user(:user) if warden.authenticated?(:user)

    return unless @user

    @account = Account.find(params[:account_id])
    @current_account_user = @account.account_users.find_by(user_id: @user.id)
  end

  def check_authorization
    return render json: { error: 'Unauthorized - please log in' }, status: :unauthorized unless @user

    # Allow administrators and owners to create checkout sessions
    return if @current_account_user&.administrator? || @current_account_user&.owner?

    render json: { error: 'Unauthorized - admin access required' }, status: :unauthorized
  end
end
