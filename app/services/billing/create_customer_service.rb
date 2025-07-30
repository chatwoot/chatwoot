# frozen_string_literal: true

module Billing
  # Service to create a new customer and subscription in the payment provider
  # Currently implemented for Stripe but designed to be provider-agnostic
  class CreateCustomerService
    include BillingPlans

    def initialize(account, plan_name = nil, trial_period_days: nil)
      @account = account
      @plan_name = plan_name || self.class.default_plan_name
      @trial_period_days = trial_period_days
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
        # Check if customer already exists to prevent duplicates on retry
        existing_customer_id = @account.custom_attributes&.dig('stripe_customer_id')
        if existing_customer_id.present?
          Rails.logger.info "Using existing Stripe customer: #{existing_customer_id}"
          customer = @provider.get_customer(existing_customer_id)
        else
          Rails.logger.info "Creating Stripe customer for account #{@account.id}"
          customer = @provider.create_customer(@account, @plan_name)
          Rails.logger.info "Customer created successfully: #{customer.id}"

          # Save customer ID immediately to prevent duplicates on retry
          save_customer_id_only(customer.id)
        end

        price_id = self.class.plan_price_id(@plan_name)
        Rails.logger.info "Plan price ID: #{price_id}"

        # Determine trial period - use provided value or get from billing plans config
        trial_days = determine_trial_period

        Rails.logger.info "Creating subscription with price_id: #{price_id}, trial_period_days: #{trial_days}"
        subscription = @provider.create_subscription(customer.id, price_id, 1, trial_period_days: trial_days)
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

      # Extract current_period_end from subscription items (where it's actually stored)
      current_period_end = if subscription.nil?
                             nil
                           else
                             # For Stripe objects, get from items.data.first.current_period_end
                             subscription.items&.data&.first&.current_period_end
                           end

      # Log subscription object details
      Rails.logger.info 'Subscription object:'
      if subscription.nil?
        Rails.logger.info '  - Subscription is nil (likely free trial plan)'
      else
        Rails.logger.info "  - Subscription class: #{subscription.class}"
        Rails.logger.info "  - Subscription ID: #{subscription.id}"
        Rails.logger.info "  - Subscription status: #{subscription.status}"
        Rails.logger.info "  - Subscription current_period_end: #{current_period_end}"
        Rails.logger.info "  - Subscription items: #{subscription.items&.data&.inspect}"
        Rails.logger.info "  - Subscription object: #{subscription.inspect}"
      end

      custom_attrs = @account.custom_attributes || {}

      # Prepare subscription attributes to merge
      subscription_attrs = {
        'stripe_customer_id' => customer.id,
        'plan_name' => @plan_name,
        'subscription_status' => subscription&.status,
        'current_period_end' => current_period_end&.to_i,
        'subscription_ends_on' => if current_period_end
                                    Time.at(current_period_end).strftime('%Y-%m-%d')
                                  else
                                    nil
                                  end
      }

      # Validate subscription attributes before merging
      validate_required_attributes(subscription_attrs)

      # Merge validated attributes
      custom_attrs.merge!(subscription_attrs)
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

    def validate_required_attributes(custom_attrs)
      required_attributes = %w[
        stripe_customer_id
        plan_name
        subscription_status
      ]

      missing_attributes = required_attributes.select do |attr|
        custom_attrs[attr].nil? || custom_attrs[attr] == ''
      end

      return if missing_attributes.empty?

      error_message = "Missing required subscription attributes: #{missing_attributes.join(', ')}"
      Rails.logger.error error_message
      raise StandardError, error_message
    end

    def clear_creating_customer_flag
      custom_attrs = @account.custom_attributes || {}
      custom_attrs.delete('is_creating_billing_customer')
      custom_attrs.delete('creating_billing_customer_since')
      @account.update!(custom_attributes: custom_attrs)
    rescue StandardError => e
      Rails.logger.error "Failed to clear creating customer flag: #{e.message}"
    end

    def save_customer_id_only(customer_id)
      custom_attrs = @account.custom_attributes || {}
      custom_attrs['stripe_customer_id'] = customer_id
      @account.update!(custom_attributes: custom_attrs)
      Rails.logger.info "Saved customer ID #{customer_id} to account #{@account.id}"
    rescue StandardError => e
      Rails.logger.error "Failed to save customer ID: #{e.message}"
    end

    def determine_trial_period
      # Return explicitly provided trial period if present
      return @trial_period_days if @trial_period_days.present?

      # Get trial period from billing plans configuration
      # Look for trial_expires_in_days in the free_trial plan as the default
      trial_plan_details = self.class.plan_details('free_trial')
      trial_days = trial_plan_details&.dig('trial_expires_in_days') || 7

      # For new signups transitioning to Stripe-managed trials,
      # we create trialing subscriptions on paid plans (like starter)
      # but use the trial period from the free_trial configuration
      return trial_days if price_id_has_value?

      # If no price_id (free plan), don't use trial period in Stripe
      nil
    end

    def price_id_has_value?
      price_id = self.class.plan_price_id(@plan_name)
      price_id.present? && price_id != 'null'
    end
  end
end