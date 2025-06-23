# frozen_string_literal: true

module Billing
  # Service to create Stripe Checkout Sessions for immediate payment processing
  # This provides a better UX by redirecting users directly to Stripe's checkout
  class CreateCheckoutSessionService
    include BillingPlans

    def initialize(account, plan_name = nil)
      @account = account
      @plan_name = plan_name || self.class.default_plan_name
      @provider = ProviderFactory.get_provider
    end

    def perform
      return failure_response('Invalid plan') unless self.class.plan_exists?(@plan_name)
      return failure_response('Account already has an active Stripe customer') if stripe_customer_exists_and_active?

      # For paid plans, validate that we have a valid price ID
      if @plan_name != 'free_trial'
        price_id = self.class.plan_price_id(@plan_name)
        if price_id.blank? || (price_id.start_with?('price_') && !price_id.start_with?('price_1'))
          return failure_response("Price ID not configured for plan '#{@plan_name}'. Please configure a valid Stripe price ID.")
        end
      end

      begin
        # For free trial conversion, we'll create a setup session that collects payment method
        # but doesn't charge immediately - the subscription will be created via webhook
        checkout_session = create_setup_session

        success_response(
          checkout_url: checkout_session.url,
          session_id: checkout_session.id
        )
      rescue StandardError => e
        Rails.logger.error "Error in CreateCheckoutSessionService: #{e.message}"
        failure_response("Checkout session creation failed: #{e.message}")
      end
    end

    private

    def stripe_customer_exists_and_active?
      return false unless @account.custom_attributes&.dig('stripe_customer_id').present?

      subscription_status = @account.custom_attributes&.dig('subscription_status')
      # Allow checkout for inactive subscriptions
      subscription_status != 'inactive'
    end

    def create_setup_session
      session_params = {
        success_url: success_url,
        cancel_url: cancel_url,
        allow_promotion_codes: true,
        metadata: {
          account_id: @account.id,
          plan_name: @plan_name
        }
      }

      # For free trial plans, we just collect payment method without charging
      if @plan_name == 'free_trial'
        session_params[:mode] = 'setup'
      else
        # For paid plans, create a subscription checkout
        price_id = self.class.plan_price_id(@plan_name)
        session_params[:mode] = 'subscription'
        session_params[:line_items] = [{
          price: price_id,
          quantity: 1
        }]

        # Propagate metadata to the subscription object for reliable account linking
        session_params[:subscription_data] = {
          metadata: {
            account_id: @account.id,
            plan_name: @plan_name
          }
        }
      end

      @provider.create_checkout_session(session_params)
    end

    def success_url
      "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/settings/billing?success=true"
    end

    def cancel_url
      "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/settings/billing?canceled=true"
    end

    def success_response(data = {})
      {
        success: true,
        data: data
      }
    end

    def failure_response(message)
      {
        success: false,
        error: message
      }
    end
  end
end