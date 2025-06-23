# frozen_string_literal: true

module Billing
  # Service to create a new customer and subscription in the payment provider
  # Currently implemented for Stripe but designed to be provider-agnostic
  class CreateCustomerService
    include BillingPlans

    def initialize(account, plan_name = nil)
      @account = account
      @plan_name = plan_name || self.class.default_plan_name
      @provider = ProviderFactory.get_provider
    end

    def perform
      Rails.logger.info '---[CREATE CUSTOMER SERVICE - PERFORM]---'
      Rails.logger.info "Account ID: #{@account.id}"
      Rails.logger.info "Plan Name: #{@plan_name}"
      Rails.logger.info "Provider: #{@provider.provider_name}"

      return failure_response('Invalid plan') unless self.class.plan_exists?(@plan_name)
      return failure_response('Account already has subscription') if subscription_exists?

      begin
        Rails.logger.info "Creating Stripe customer for account #{@account.id}"
        customer = @provider.create_customer(@account, @plan_name)
        Rails.logger.info "Customer created successfully: #{customer.id}"

        price_id = self.class.plan_price_id(@plan_name)
        Rails.logger.info "Plan price ID: #{price_id}"

        Rails.logger.info "Creating subscription with price_id: #{price_id}"
        subscription = @provider.create_subscription(customer.id, price_id, 1) # Default quantity is 1
        Rails.logger.info "Subscription created successfully: #{subscription&.id || 'nil (free trial plan)'}"

        update_account_attributes(customer, subscription)
        sync_account_features

        Rails.logger.info 'CreateCustomerService completed successfully'
        success_response(customer: customer, subscription: subscription)
      rescue StandardError => e
        Rails.logger.error "Error in CreateCustomerService: #{e.message}"
        Rails.logger.error "Error backtrace: #{e.backtrace.first(5).join("\n")}"
        clear_creating_customer_flag
        failure_response("Subscription creation failed: #{e.message}")
      end
    end

    private

    def subscription_exists?
      @account.custom_attributes&.dig('stripe_customer_id').present?
    end

    def update_account_attributes(customer, subscription)
      Rails.logger.info '---[CREATE CUSTOMER SERVICE - UPDATE ACCOUNT ATTRIBUTES]---'
      Rails.logger.info "Account ID: #{@account.id}"
      Rails.logger.info "Plan Name: #{@plan_name}"

      # Log customer object details
      Rails.logger.info 'Customer object:'
      Rails.logger.info "  - Customer class: #{customer.class}"
      Rails.logger.info "  - Customer ID: #{customer.id}"
      Rails.logger.info "  - Customer object: #{customer.inspect}"

      # Log subscription object details
      Rails.logger.info 'Subscription object:'
      if subscription.nil?
        Rails.logger.info '  - Subscription is nil (likely free trial plan)'
      else
        Rails.logger.info "  - Subscription class: #{subscription.class}"
        Rails.logger.info "  - Subscription ID: #{subscription.id}"
        Rails.logger.info "  - Subscription status: #{subscription.status}"
        Rails.logger.info "  - Subscription current_period_end: #{subscription.current_period_end}"
        Rails.logger.info "  - Subscription items: #{subscription.items&.data&.inspect}"
        Rails.logger.info "  - Subscription object: #{subscription.inspect}"
      end

      custom_attrs = @account.custom_attributes || {}

      custom_attrs.merge!(
        'stripe_customer_id' => customer.id,
        'plan_name' => @plan_name,
        'subscription_status' => subscription&.status || '-',
        'current_period_end' => subscription&.current_period_end&.to_i,
        'subscribed_quantity' => subscription&.items&.data&.first&.quantity || 1,
        'subscription_ends_on' => if subscription&.current_period_end
                                    Time.at(subscription.current_period_end).strftime('%Y-%m-%d')
                                  else
                                    nil
                                  end
      )

      Rails.logger.info "Final custom_attrs being saved: #{custom_attrs.inspect}"

      # Clear the creating customer flag and timestamp
      custom_attrs.delete('is_creating_billing_customer')
      custom_attrs.delete('creating_billing_customer_since')

      @account.update!(custom_attributes: custom_attrs)
      Rails.logger.info 'Account updated successfully with new billing attributes'
    end

    def sync_account_features
      Billing::SyncAccountFeaturesService.new(@account, @plan_name).perform
    end

    def success_response(data = {})
      {
        success: true,
        data: data,
        message: "Subscription created successfully for #{@plan_name} plan"
      }
    end

    def failure_response(message)
      {
        success: false,
        error: message,
        data: {}
      }
    end

    def clear_creating_customer_flag
      custom_attrs = @account.custom_attributes || {}
      custom_attrs.delete('is_creating_billing_customer')
      custom_attrs.delete('creating_billing_customer_since')
      @account.update!(custom_attributes: custom_attrs)
    rescue StandardError => e
      Rails.logger.error "Failed to clear creating customer flag: #{e.message}"
    end
  end
end