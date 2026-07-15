class Enterprise::Api::V1::AccountsController < Api::BaseController
  include BillingHelper
  before_action :fetch_account
  before_action :check_authorization
  before_action :check_cloud_env, only: [:limits, :toggle_deletion, :topup_options]

  def subscription
    return render json: currency_selection_payload if @account.billing_currency_selection_required?

    ensure_stripe_customer
    head :no_content
  end

  def select_billing_currency
    return render_could_not_create_error(I18n.t('errors.billing.currency_locked')) if currency_locked?
    return render_could_not_create_error(I18n.t('errors.billing.invalid_currency')) unless @account.billing_currency_selection_required?

    currency = Enterprise::Billing::Currencies.normalize(params[:currency])
    return render_could_not_create_error(I18n.t('errors.billing.invalid_currency')) unless Enterprise::Billing::Currencies.supported?(currency)

    @account.update!(custom_attributes: @account.custom_attributes.merge('billing_currency' => currency))
    ensure_stripe_customer
    head :no_content
  end

  def limits
    limits = if default_plan?(@account)
               {
                 'conversation' => {
                   'allowed' => 500,
                   'consumed' => conversations_this_month(@account)
                 },
                 'non_web_inboxes' => {
                   'allowed' => 0,
                   'consumed' => non_web_inboxes(@account)
                 },
                 'agents' => {
                   'allowed' => 2,
                   'consumed' => agents(@account)
                 }
               }
             else
               default_limits
             end

    # include id in response to ensure that the store can be updated on the frontend
    render json: { id: @account.id, limits: limits }, status: :ok
  end

  def checkout
    return create_stripe_billing_session(stripe_customer_id) if stripe_customer_id.present?

    render_invalid_billing_details
  end

  def toggle_deletion
    action_type = params[:action_type]

    case action_type
    when 'delete'
      mark_for_deletion
    when 'undelete'
      unmark_for_deletion
    else
      render json: { error: 'Invalid action_type. Must be either "delete" or "undelete"' }, status: :unprocessable_entity
    end
  end

  def topup_checkout
    return render json: { error: I18n.t('errors.topup.credits_required') }, status: :unprocessable_entity if params[:credits].blank?

    service = Enterprise::Billing::TopupCheckoutService.new(account: @account)
    result = service.create_checkout_session(credits: params[:credits].to_i)

    @account.reload
    render json: result.merge(
      id: @account.id,
      limits: @account.limits,
      custom_attributes: @account.custom_attributes
    )
  rescue Enterprise::Billing::TopupCheckoutService::Error, Stripe::StripeError => e
    render_could_not_create_error(e.message)
  end

  def topup_options
    service = Enterprise::Billing::TopupCheckoutService.new(account: @account)
    render json: { id: @account.id, currency: @account.billing_currency, options: service.available_options }
  end

  private

  def check_cloud_env
    render json: { error: 'Not found' }, status: :not_found unless ChatwootApp.chatwoot_cloud?
  end

  def ensure_stripe_customer
    return if stripe_customer_id.present? || @account.custom_attributes['is_creating_customer'].present?

    @account.update!(custom_attributes: @account.custom_attributes.merge('is_creating_customer' => true))
    Enterprise::CreateStripeCustomerJob.perform_later(@account)
  end

  def currency_selection_payload
    {
      currency_selection_required: true,
      currency_options: Enterprise::Billing::Currencies::SUPPORTED,
      suggested_currency: Enterprise::Billing::Currencies.for_locale(@account.locale)
    }
  end

  def default_limits
    {
      'conversation' => {},
      'non_web_inboxes' => {},
      'agents' => {
        'allowed' => @account.usage_limits[:agents],
        'consumed' => agents(@account)
      },
      'captain' => @account.usage_limits[:captain]
    }
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def stripe_customer_id
    @account.custom_attributes['stripe_customer_id']
  end

  # Currency is fixed once a customer exists or creation is already in flight,
  # so a second click can't bill a different currency than setup started with.
  def currency_locked?
    stripe_customer_id.present? || @account.custom_attributes['is_creating_customer'].present?
  end

  def mark_for_deletion
    reason = 'manual_deletion'

    if @account.mark_for_deletion(reason)
      cancel_cloud_subscriptions_for_deletion

      render json: { message: 'Account marked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def unmark_for_deletion
    if @account.unmark_for_deletion
      render json: { message: 'Account unmarked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def render_invalid_billing_details
    render_could_not_create_error('Please subscribe to a plan before viewing the billing details')
  end

  def create_stripe_billing_session(customer_id)
    session = Enterprise::Billing::CreateSessionService.new.create_session(customer_id)
    render_redirect_url(session.url)
  end

  def cancel_cloud_subscriptions_for_deletion
    Enterprise::Billing::CancelCloudSubscriptionsService.new(account: @account).perform
  rescue Stripe::StripeError => e
    Rails.logger.warn("Failed to cancel cloud subscriptions for account #{@account.id}: #{e.class} - #{e.message}")
  end

  def render_redirect_url(redirect_url)
    render json: { redirect_url: redirect_url }
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
