# frozen_string_literal: true

module Billing
  module Providers
    # Base class for all payment providers. This defines the interface that all
    # provider-specific classes must implement to ensure consistency across
    # different payment systems (Stripe, Paddle, PayPal, etc.).
    #
    # All methods in this class raise NotImplementedError to force subclasses
    # to implement the required functionality.
    class Base
      # Creates a customer in the payment provider's system
      #
      # @param account [Account] The Chatwoot account to create a customer for
      # @param plan_name [String] The plan the customer should be subscribed to
      # @return [Object] Provider-specific customer object
      # @raise [NotImplementedError] if not implemented by subclass
      def create_customer(_account, _plan_name)
        raise NotImplementedError, "#{self.class.name} must implement #create_customer"
      end

      # Creates a subscription for a customer
      #
      # @param customer_id [String] The provider's customer ID
      # @param plan_id [String] The provider's plan/price ID
      # @param quantity [Integer] Number of licenses/seats
      # @return [Object, nil] Provider-specific subscription object, or nil for free trial plans
      # @raise [NotImplementedError] if not implemented by subclass
      def create_subscription(_customer_id, _plan_id, _quantity)
        raise NotImplementedError, "#{self.class.name} must implement #create_subscription"
      end

      # Creates a billing portal session for customer self-service
      #
      # @param customer_id [String] The provider's customer ID
      # @param return_url [String] URL to redirect to after portal session
      # @return [Object] Provider-specific portal session object
      # @raise [NotImplementedError] if not implemented by subclass
      def create_portal_session(_customer_id, _return_url)
        raise NotImplementedError, "#{self.class.name} must implement #create_portal_session"
      end

      # Handles incoming webhook events from the payment provider
      #
      # @param event_data [Hash] The webhook event data
      # @return [Hash] Response with success/error status and message
      # @raise [NotImplementedError] if not implemented by subclass
      def handle_webhook(_event_data)
        raise NotImplementedError, "#{self.class.name} must implement #handle_webhook"
      end

      # Verifies webhook signature to ensure authenticity
      #
      # @param payload [String] Raw webhook payload
      # @param signature [String] Webhook signature header
      # @param secret [String] Webhook secret for verification
      # @return [Boolean] true if signature is valid
      # @raise [NotImplementedError] if not implemented by subclass
      def verify_webhook_signature(_payload, _signature, _secret)
        raise NotImplementedError, "#{self.class.name} must implement #verify_webhook_signature"
      end

      # Retrieves customer information from the provider
      #
      # @param customer_id [String] The provider's customer ID
      # @return [Object] Provider-specific customer object
      # @raise [NotImplementedError] if not implemented by subclass
      def get_customer(_customer_id)
        raise NotImplementedError, "#{self.class.name} must implement #get_customer"
      end

      # Retrieves subscription information from the provider
      #
      # @param subscription_id [String] The provider's subscription ID
      # @return [Object] Provider-specific subscription object
      # @raise [NotImplementedError] if not implemented by subclass
      def get_subscription(_subscription_id)
        raise NotImplementedError, "#{self.class.name} must implement #get_subscription"
      end

      # Returns the provider name (e.g., 'stripe', 'paddle', 'paypal')
      #
      # @return [String] Provider name in lowercase
      # @raise [NotImplementedError] if not implemented by subclass
      def provider_name
        raise NotImplementedError, "#{self.class.name} must implement #provider_name"
      end

      # Cancels a subscription
      #
      # @param subscription_id [String] The provider's subscription ID
      # @return [Object] Provider-specific cancellation result
      # @raise [NotImplementedError] if not implemented by subclass
      def cancel_subscription(_subscription_id)
        raise NotImplementedError, "#{self.class.name} must implement #cancel_subscription"
      end

      # Updates a subscription (e.g., change plan, quantity)
      #
      # @param subscription_id [String] The provider's subscription ID
      # @param options [Hash] Update options (plan_id, quantity, etc.)
      # @return [Object] Provider-specific updated subscription object
      # @raise [NotImplementedError] if not implemented by subclass
      def update_subscription(_subscription_id, _options = {})
        raise NotImplementedError, "#{self.class.name} must implement #update_subscription"
      end
    end
  end
end