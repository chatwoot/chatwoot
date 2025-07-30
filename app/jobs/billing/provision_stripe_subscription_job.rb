# frozen_string_literal: true

module Billing
  # Background job to handle Stripe subscription provisioning for new accounts
  # This provides a fallback strategy when the Stripe API is down during signup
  class ProvisionStripeSubscriptionJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 5 # Retry 5 times on failure

    def perform(account_id, plan_name)
      Rails.logger.info "Starting Stripe subscription provisioning for account #{account_id} with plan #{plan_name}"

      account = Account.find_by(id: account_id)
      unless account
        Rails.logger.error "Account not found with ID: #{account_id}. This may indicate a race condition where the job was enqueued before the account was committed to the database."
        return
      end

      # Check if already provisioned
      if account.custom_attributes&.dig('stripe_customer_id').present?
        Rails.logger.info "Account #{account_id} already has Stripe customer ID, skipping provisioning"
        return
      end

      begin
        # Use the existing CreateCustomerService to provision the Stripe subscription
        # For new signups, we want to create a trialing subscription
        trial_days = get_trial_period_for_plan(plan_name)
        result = Billing::CreateCustomerService.new(account, plan_name, trial_period_days: trial_days).perform

        if result[:success]
          Rails.logger.info "Successfully provisioned Stripe subscription for account #{account_id}"
          # Remove the provisioning pending status
          update_provisioning_status(account, 'completed')
        else
          Rails.logger.error "Failed to provision Stripe subscription for account #{account_id}: #{result[:error]}"
          update_provisioning_status(account, 'failed')
          raise StandardError, result[:error]
        end
      rescue StandardError => e
        Rails.logger.error "Error provisioning Stripe subscription for account #{account_id}: #{e.message}"
        update_provisioning_status(account, 'failed')
        raise e
      end
    end

    private

    def update_provisioning_status(account, status)
      custom_attrs = account.custom_attributes || {}
      custom_attrs['billing_status'] = status
      custom_attrs['billing_provisioned_at'] = Time.current.iso8601 if status == 'completed'
      account.update!(custom_attributes: custom_attrs)
    rescue StandardError => e
      Rails.logger.error "Failed to update provisioning status for account #{account.id}: #{e.message}"
    end

    def get_trial_period_for_plan(_plan_name)
      # For new Stripe-managed trials, we always use the trial period from billing config
      # regardless of the target plan (starter, professional, etc.)
      billing_plans_class = Class.new { include BillingPlans }.new
      trial_plan_details = billing_plans_class.class.plan_details('free_trial')
      trial_plan_details&.dig('trial_expires_in_days') || 7
    end
  end
end