# frozen_string_literal: true

class Api::V2::Accounts::SubscriptionsController < Api::BaseController
  include SwitchLocale
  include EnsureCurrentAccountHelper

  before_action :current_account
  before_action :check_authorization

  # GET /api/v2/accounts/:account_id/subscription
  def show
    subscription_data = extract_subscription_data

    render json: {
      success: true,
      data: subscription_data
    }
  rescue StandardError => e
    Rails.logger.error "Error fetching subscription: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to fetch subscription data.'
    }, status: :internal_server_error
  end

  # POST /api/v2/accounts/:account_id/subscription
  def create
    plan_name = subscription_params[:plan_name] || 'free_trial'

    # Check if customer creation is already in progress (with timeout)
    if customer_creation_in_progress?
      return render json: {
        success: false,
        error: 'Subscription creation already in progress'
      }, status: :conflict
    end

    # Check if customer already exists (only reject if they have an active Stripe customer)
    # Allow trial accounts (those with plan_name but no stripe_customer_id) to proceed
    # Allow inactive subscriptions to create new subscriptions
    if current_account.custom_attributes&.dig('stripe_customer_id').present?
      subscription_status = current_account.custom_attributes&.dig('subscription_status')

      # Allow subscription creation for inactive subscriptions
      unless subscription_status == 'inactive'
        return render json: {
          success: false,
          error: 'Account already has an active Stripe customer'
        }, status: :conflict
      end
    end

    # For free trial users and starter plan, create Stripe Checkout Session immediately
    if %w[free_trial starter].include?(plan_name)
      service = Billing::CreateCheckoutSessionService.new(current_account, plan_name)
      result = service.perform

      if result[:success]
        render json: {
          success: true,
          message: 'Checkout session created successfully',
          data: {
            checkout_url: result[:data][:checkout_url],
            session_id: result[:data][:session_id]
          }
        }
      else
        render json: {
          success: false,
          error: result[:error]
        }, status: :unprocessable_entity
      end
    else
      # For paid plans, use the background job approach
      # Mark as creating customer to prevent duplicate requests
      custom_attrs = current_account.custom_attributes || {}
      custom_attrs['is_creating_billing_customer'] = true
      custom_attrs['creating_billing_customer_since'] = Time.current.iso8601
      current_account.update!(custom_attributes: custom_attrs)

      # Enqueue background job for customer creation
      Billing::CreateCustomerJob.perform_later(current_account, plan_name)

      render json: {
        success: true,
        message: 'Subscription creation initiated. You will be notified when complete.',
        data: {
          account_id: current_account.id,
          plan_name: plan_name,
          status: 'processing'
        }
      }, status: :accepted
    end
  rescue StandardError => e
    Rails.logger.error "Error creating subscription: #{e.message}"
    render json: {
      success: false,
      error: 'Subscription creation failed. Please try again.'
    }, status: :internal_server_error
  end

  # GET /api/v2/accounts/:account_id/subscription/portal
  def portal
    return_url = portal_params[:return_url] || default_return_url

    service = Billing::CreatePortalSessionService.new(current_account, return_url)
    result = service.perform

    if result[:success]
      render json: {
        success: true,
        message: result[:message],
        data: result[:data]
      }
    else
      render json: {
        success: false,
        error: result[:error]
      }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Error creating portal session: #{e.message}"
    render json: {
      success: false,
      error: 'Portal session creation failed. Please try again.'
    }, status: :internal_server_error
  end

  # GET /api/v2/accounts/:account_id/subscription/limits
  def limits
    limits_data = calculate_account_limits

    render json: {
      success: true,
      data: {
        id: current_account.id,
        limits: limits_data
      }
    }
  rescue StandardError => e
    Rails.logger.error "Error fetching limits: #{e.message}"
    render json: {
      success: false,
      error: 'Failed to fetch account limits.'
    }, status: :internal_server_error
  end

  private

  def subscription_params
    params.require(:subscription).permit(:plan_name)
  rescue ActionController::ParameterMissing
    {}
  end

  def portal_params
    params.permit(:return_url)
  end

  def default_return_url
    # Use the frontend billing URL as default return
    "#{request.base_url}/app/accounts/#{current_account.id}/settings/billing"
  end

  def extract_subscription_data
    custom_attrs = current_account.custom_attributes || {}

    {
      account_id: current_account.id,
      plan_name: custom_attrs['plan_name'] || 'free_trial',
      subscription_status: custom_attrs['subscription_status'] || 'free_trial',
      customer_id: custom_attrs['stripe_customer_id'],
      current_period_end: custom_attrs['current_period_end'],
      subscription_ends_on: custom_attrs['subscription_ends_on'],
      subscribed_quantity: custom_attrs['subscribed_quantity'] || 1,
      last_payment_status: custom_attrs['last_payment_status'],
      last_payment_date: custom_attrs['last_payment_date'],
      plan_limits: custom_attrs['plan_limits'],
      cancel_at_period_end: custom_attrs['cancel_at_period_end'],
      canceled_at: custom_attrs['canceled_at'],
      ended_at: custom_attrs['ended_at']
    }
  end

  def calculate_account_limits
    plan_name = current_account.custom_attributes&.dig('plan_name') || 'free_trial'
    plan_limits = Billing::SyncAccountFeaturesService.new(current_account, plan_name).class.plan_limits(plan_name)

    # If it's a free trial plan, show specific limits
    if plan_name == 'free_trial' || plan_limits.blank?
      {
        'agents' => {
          'allowed' => plan_limits['agents'] || 1,
          'consumed' => current_account.users.count
        },
        'inboxes' => {
          'allowed' => plan_limits['inboxes'] || 1,
          'consumed' => current_account.inboxes.count
        },
        'conversations' => {
          'allowed' => plan_limits['conversations'] || 500,
          'consumed' => conversations_this_month
        }
      }
    else
      # For paid plans, show unlimited or plan-specific limits
      {
        'agents' => calculate_limit_data('agents', plan_limits['agents'], current_account.users.count),
        'inboxes' => calculate_limit_data('inboxes', plan_limits['inboxes'], current_account.inboxes.count),
        'conversations' => calculate_limit_data('conversations', plan_limits['conversations'], conversations_this_month)
      }
    end
  end

  def calculate_limit_data(type, allowed, consumed)
    if allowed == -1
      { 'allowed' => 'unlimited', 'consumed' => consumed }
    else
      { 'allowed' => allowed, 'consumed' => consumed }
    end
  end

  def conversations_this_month
    current_account.conversations.where(created_at: Time.current.all_month).count
  end

  def customer_creation_in_progress?
    custom_attrs = current_account.custom_attributes || {}
    return false unless custom_attrs['is_creating_billing_customer']

    # Check if the flag was set more than 5 minutes ago (timeout)
    created_at = custom_attrs['creating_billing_customer_since']
    if created_at.present?
      created_time = Time.parse(created_at)
      if Time.current - created_time > 5.minutes
        # Clear the stuck flag
        clear_customer_creation_flag
        return false
      end
    end

    true
  rescue StandardError
    # If there's any error parsing the timestamp, clear the flag
    clear_customer_creation_flag
    false
  end

  def clear_customer_creation_flag
    custom_attrs = current_account.custom_attributes || {}
    custom_attrs.delete('is_creating_billing_customer')
    custom_attrs.delete('creating_billing_customer_since')
    current_account.update!(custom_attributes: custom_attrs)
  end

  def check_authorization
    authorize(:account, :billing_access?)
  rescue Pundit::NotAuthorizedError
    render json: { error: 'Access denied' }, status: :forbidden
  end
end