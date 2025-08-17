# frozen_string_literal: true

module Billing
  module Providers
    # Stripe implementation of the payment provider interface.
    # This class encapsulates all Stripe-specific logic and API interactions.
    class Stripe < Base
      include BillingPlans
      # Creates a customer in Stripe
      def create_customer(account, plan_name)
        ::Stripe::Customer.create(
          email: account.users.first&.email,
          name: account.name,
          metadata: {
            account_id: account.id,
            plan: plan_name
          }
        )
      rescue ::Stripe::StripeError => e
        Rails.logger.error "Stripe error creating customer: #{e.message}"
        raise StandardError, "Failed to create customer: #{e.message}"
      end

      # Creates a subscription in Stripe
      def create_subscription(customer_id, plan_id, quantity, trial_period_days: nil)
        return nil if plan_id.nil? # Free trial plans don't need a Stripe subscription

        # Build subscription parameters
        subscription_params = {
          customer: customer_id,
          items: [{ price: plan_id, quantity: 1 }], # Fixed quantity - cost is per plan, not per agent
          auto_advance: true,
          collection_method: 'charge_automatically',
          metadata: {
            plan_id: plan_id,
            quantity: quantity # This metadata quantity is for reference, not billing
          }
        }

        # Add trial parameter if provided
        if trial_period_days.present? && trial_period_days > 0
          subscription_params[:trial_period_days] = trial_period_days
          Rails.logger.info "Creating trialing subscription with #{trial_period_days} days trial"
        end

        ::Stripe::Subscription.create(subscription_params)
      rescue ::Stripe::StripeError => e
        Rails.logger.error "Stripe error creating subscription: #{e.message}"
        raise StandardError, "Failed to create subscription: #{e.message}"
      end

      # Creates a billing portal session in Stripe
      def create_portal_session(customer_id, return_url)
        ::Stripe::BillingPortal::Session.create(
          customer: customer_id,
          return_url: return_url
        )
      rescue ::Stripe::StripeError => e
        # Handle the specific case where portal configuration is missing
        if e.message.include?('No configuration provided')
          Rails.logger.error 'Stripe Customer Portal not configured. Please configure it at: https://dashboard.stripe.com/test/settings/billing/portal'
          raise StandardError, 'Customer portal is not configured. Please set up the billing portal in your Stripe Dashboard at https://dashboard.stripe.com/test/settings/billing/portal'
        else
          Rails.logger.error "Stripe error creating portal session: #{e.message}"
          raise StandardError, "Failed to create portal session: #{e.message}"
        end
      end

      # Creates a checkout session in Stripe
      def create_checkout_session(session_params)
        ::Stripe::Checkout::Session.create(session_params)
      rescue ::Stripe::StripeError => e
        Rails.logger.error "Stripe error creating checkout session: #{e.message}"
        raise StandardError, "Failed to create checkout session: #{e.message}"
      end

      # Handles Stripe webhook events
      def handle_webhook(event_data)
        event_type = event_data['type']
        event_object = event_data['data']['object']

        Rails.logger.info "Processing Stripe webhook: #{event_type}"

        case event_type
        when 'checkout.session.completed'
          handle_checkout_session_completed(event_object)
        when 'customer.subscription.created'
          handle_subscription_created(event_object)
        when 'customer.subscription.updated'
          handle_subscription_updated(event_object)
        when 'customer.subscription.deleted'
          handle_subscription_deleted(event_object)
        when 'invoice.payment_succeeded'
          handle_payment_succeeded(event_object)
        when 'invoice.payment_failed'
          handle_payment_failed(event_object)
        else
          Rails.logger.info "Unhandled Stripe webhook event: #{event_type}"
          { success: true, message: "Event #{event_type} acknowledged but not processed" }
        end
      rescue StandardError => e
        Rails.logger.error "Error handling Stripe webhook #{event_type}: #{e.message}"
        { success: false, error: "Webhook processing failed: #{e.message}" }
      end

      # Verifies Stripe webhook signature
      def verify_webhook_signature(payload, signature, secret)
        ::Stripe::Webhook.construct_event(payload, signature, secret)
        true
      rescue ::Stripe::SignatureVerificationError => e
        Rails.logger.error "Stripe webhook signature verification failed: #{e.message}"
        false
      end

      # Retrieves a customer from Stripe
      def get_customer(customer_id)
        ::Stripe::Customer.retrieve(customer_id)
      rescue ::Stripe::StripeError => e
        Rails.logger.error "Stripe error retrieving customer: #{e.message}"
        raise StandardError, "Failed to retrieve customer: #{e.message}"
      end

      # Retrieves a subscription from Stripe
      def get_subscription(subscription_id)
        ::Stripe::Subscription.retrieve(subscription_id)
      rescue ::Stripe::StripeError => e
        Rails.logger.error "Stripe error retrieving subscription: #{e.message}"
        raise StandardError, "Failed to retrieve subscription: #{e.message}"
      end

      # Returns the provider name
      def provider_name
        'stripe'
      end

      # Cancels a subscription in Stripe
      def cancel_subscription(subscription_id)
        ::Stripe::Subscription.cancel(subscription_id)
      rescue ::Stripe::StripeError => e
        Rails.logger.error "Stripe error cancelling subscription: #{e.message}"
        raise StandardError, "Failed to cancel subscription: #{e.message}"
      end

      # Updates a subscription in Stripe
      def update_subscription(subscription_id, options = {})
        update_params = {}

        if options[:plan_id]
          update_params[:items] = [{
            id: get_subscription(subscription_id).items.data[0].id,
            price: options[:plan_id]
          }]
        end

        update_params[:quantity] = options[:quantity] if options[:quantity]
        update_params[:metadata] = options[:metadata] if options[:metadata]

        ::Stripe::Subscription.update(subscription_id, update_params)
      rescue ::Stripe::StripeError => e
        Rails.logger.error "Stripe error updating subscription: #{e.message}"
        raise StandardError, "Failed to update subscription: #{e.message}"
      end

      private

      # Handles checkout session completed events
      def handle_checkout_session_completed(session)
        Rails.logger.info '---[STRIPE PROVIDER - CHECKOUT SESSION COMPLETED]---'
        # Extract data from the session object
        stripe_customer_id = session['customer']
        subscription_id = session['subscription']
        account_id = session.dig('metadata', 'account_id')
        plan_name = session.dig('metadata', 'plan_name')

        Rails.logger.info "Account ID from metadata: #{account_id}"
        Rails.logger.info "Plan Name from metadata: #{plan_name}"

        # Find the account using the reliable account_id from metadata
        account = Account.find_by(id: account_id)
        unless account
          Rails.logger.error "Account not found with ID: #{account_id}"
          return failure_response('Account not found from checkout session metadata')
        end
        Rails.logger.info "Found account: #{account.id} - #{account.name}"

        # Retrieve the full subscription object to get all details
        subscription = get_subscription(subscription_id)
        unless subscription
          Rails.logger.error "Subscription not found with ID: #{subscription_id}"
          return failure_response('Subscription details not found')
        end

        # Handle logging for both Hash and Stripe object types
        subscription_id_for_log = subscription.is_a?(Hash) ? subscription['id'] || subscription_id : subscription.id
        Rails.logger.info "Retrieved subscription: #{subscription_id_for_log}"

        # Update the account with all necessary billing attributes
        update_account_subscription_data(account, subscription, plan_name, stripe_customer_id)

        # Sync features based on the new plan
        sync_account_features(account, subscription)

        Rails.logger.info "Account #{account.id} updated successfully."
        success_response('Checkout session completed and account updated successfully.')
      end

      # Handles subscription created events
      def handle_subscription_created(subscription)
        # Try to find account by metadata first (more reliable)
        account_id = subscription.dig('metadata', 'account_id')
        account = account_id ? Account.find_by(id: account_id) : nil

        # Fallback to finding by customer ID
        account ||= find_account_by_customer_id(subscription['customer'])
        return failure_response('Account not found') unless account

        # Extract plan name and customer ID from subscription
        plan_name = subscription.dig('metadata', 'plan_name')
        stripe_customer_id = subscription['customer']

        update_account_subscription_data(account, subscription, plan_name, stripe_customer_id)
        sync_account_features(account, subscription)

        success_response('Subscription created and account updated')
      end

      # Handles subscription updated events
      def handle_subscription_updated(subscription)
        account = find_account_by_customer_id(subscription['customer'])
        return failure_response('Account not found') unless account

        # Get subscription status
        subscription_status = subscription.is_a?(Hash) ? subscription['status'] : subscription.status
        Rails.logger.info "Subscription status updated to: #{subscription_status}"

        # Handle subscription statuses that should transition to community plan
        if Billing::SubscriptionStatuses.failed_payment_status?(subscription_status)
          Rails.logger.info "---[STRIPE PROVIDER - HANDLING #{subscription_status.upcase} TRANSITION]---"
          Rails.logger.info "Account #{account.id} subscription is now #{subscription_status} - transitioning to community plan"

          target_plan = 'community'

          # Update account attributes with new status
          update_account_subscription_data(account, subscription)
          Rails.logger.info "Account attributes updated with #{subscription_status} status"

          # Sync features to community plan (removes premium features immediately)
          Rails.logger.info "Performing feature sync to plan: #{target_plan}"
          Billing::SyncAccountFeaturesService.new(account, target_plan).perform
          Rails.logger.info "Feature sync completed. Account #{account.id} transitioned to #{target_plan} plan"

          success_response("Subscription #{subscription_status} - account transitioned to community plan")
        else
          # Normal subscription update handling for paid statuses (active/trialing)
          update_account_subscription_data(account, subscription)
          sync_account_features(account, subscription)

          success_response('Subscription updated and account synchronized')
        end
      end

      # Handles subscription deleted events
      def handle_subscription_deleted(subscription)
        Rails.logger.info '---[STRIPE PROVIDER - HANDLE SUBSCRIPTION DELETED]---'
        account = find_account_by_customer_id(subscription['customer'])
        return failure_response('Account not found') unless account

        Rails.logger.info "Account found: #{account.id}"
        Rails.logger.info "Subscription deletion reason: #{subscription['status']} -> deleted"

        # Check if this was a trialing subscription that expired
        subscription_status = subscription['status']
        Rails.logger.info "Previous subscription status: #{subscription_status}"

        target_plan = 'community'
        Rails.logger.info "Transitioning account to #{target_plan} plan due to subscription deletion"

        # Update account attributes with subscription deletion tracking
        update_account_attributes(account, subscription, target_plan)
        Rails.logger.info "Account attributes updated. Features before sync: #{account.enabled_features.keys}"

        # Sync features to community plan (this will disable premium features)
        Rails.logger.info "Performing feature sync to plan: #{target_plan}"
        Billing::SyncAccountFeaturesService.new(account, target_plan).perform
        Rails.logger.info "Feature sync completed. Features after sync: #{account.reload.enabled_features.keys}"

        # Update billing status to indicate trial has ended
        update_billing_status(account, 'trial_expired')

        Rails.logger.info "Account #{account.id} transitioned to #{target_plan} plan successfully"

        success_response("Subscription deleted, account transitioned to #{target_plan} plan")
      end

      # Handles successful payment events
      def handle_payment_succeeded(invoice)
        # Try to find account by metadata first (more reliable for invoices from checkout sessions)
        account_id = extract_account_id_from_invoice(invoice)
        account = account_id ? Account.find_by(id: account_id) : nil

        # Fallback to finding by customer ID if metadata lookup fails
        account ||= find_account_by_customer_id(invoice['customer'])

        return failure_response('Account not found') unless account

        update_payment_status(account, 'succeeded')

        success_response('Payment succeeded, account updated')
      end

      # Handles failed payment events
      def handle_payment_failed(invoice)
        # Try to find account by metadata first (more reliable for invoices from checkout sessions)
        account_id = extract_account_id_from_invoice(invoice)
        account = account_id ? Account.find_by(id: account_id) : nil

        # Fallback to finding by customer ID if metadata lookup fails
        account ||= find_account_by_customer_id(invoice['customer'])

        return failure_response('Account not found') unless account

        update_payment_status(account, 'failed')

        success_response('Payment failed, account status updated')
      end

      # Extracts account ID from invoice metadata (line items or subscription details)
      def extract_account_id_from_invoice(invoice)
        # First try to get from line items metadata
        line_items = invoice.dig('lines', 'data') || []
        line_items.each do |line_item|
          account_id = line_item.dig('metadata', 'account_id')
          return account_id if account_id.present?
        end

        # Try to get from subscription details metadata
        subscription_metadata = invoice.dig('parent', 'subscription_details', 'metadata')
        account_id = subscription_metadata&.dig('account_id')
        return account_id if account_id.present?

        # Try to get from invoice metadata directly
        account_id = invoice.dig('metadata', 'account_id')
        return account_id if account_id.present?

        nil
      end

      # Finds account by Stripe customer ID
      def find_account_by_customer_id(customer_id)
        Account.where("custom_attributes ->> 'stripe_customer_id' = ?", customer_id).first
      end

      # Updates account with subscription data
      def update_account_subscription_data(account, subscription, plan_name = nil, stripe_customer_id = nil)
        Rails.logger.info '---[STRIPE PROVIDER - UPDATE ACCOUNT SUBSCRIPTION DATA]---'
        Rails.logger.info "Account ID: #{account.id}"
        Rails.logger.info "Subscription class: #{subscription.class}"

        # Log the full subscription object to understand its structure
        if subscription.is_a?(Hash)
          Rails.logger.info "Subscription data (Hash): #{subscription.inspect}"
        else
          Rails.logger.info 'Subscription object attributes:'
          Rails.logger.info "  - id: #{subscription.id}"
          Rails.logger.info "  - status: #{subscription.status}"
          Rails.logger.info "  - items: #{subscription.items&.data&.first&.inspect}"
        end

        custom_attrs = account.custom_attributes || {}

        Rails.logger.info 'Step 1: Extracting plan name'
        plan_name ||= extract_plan_name_from_subscription(subscription)

        # Defensive check: ensure plan_name is a string
        plan_name = plan_name.to_s if plan_name.present?
        Rails.logger.info "Plan name extracted: #{plan_name} (class: #{plan_name.class})"

        Rails.logger.info 'Step 2: Extracting customer ID'

        # Handle both Stripe objects and hashes
        stripe_customer_id ||= subscription.is_a?(Hash) ? subscription['customer'] : subscription.customer

        Rails.logger.info 'Step 3: Building new attributes hash'

        # Extract current_period_end from subscription items (where it's actually stored)
        current_period_end = if subscription.is_a?(Hash)
                               # For hash data, get from items.data[0].current_period_end
                               subscription.dig('items', 'data', 0, 'current_period_end')
                             else
                               # For Stripe objects, get from items.data.first.current_period_end
                               subscription.items&.data&.first&.current_period_end
                             end

        Rails.logger.info "current_period_end value: #{current_period_end}"
        Rails.logger.info "current_period_end class: #{current_period_end.class}"

        # Handle both Stripe objects and hashes for status
        raw_status = subscription.is_a?(Hash) ? subscription['status'] : subscription.status

        # Determine the correct subscription status based on cancellation state
        subscription_status = if extract_cancel_at_period_end(subscription)
                                'cancelled'  # User has cancelled, waiting for period to end
                              elsif extract_ended_at(subscription).present?
                                Billing::SubscriptionStatuses::INACTIVE   # Subscription has actually ended
                              else
                                raw_status   # Use Stripe's status (active, trialing, etc.)
                              end

        Rails.logger.info "Raw Stripe status: #{raw_status}, Determined status: #{subscription_status}"

        # Extract limits from billing provider metadata first
        Rails.logger.info '🔍 Step 3a: Attempting to extract plan limits from Stripe product metadata...'
        begin
          plan_limits = extract_plan_limits_from_subscription(subscription)
          Rails.logger.info "✅ Plan limits extracted successfully: #{plan_limits}"
        rescue StandardError => e
          Rails.logger.error '❌ Error extracting plan limits:'
          Rails.logger.error "  - Error message: #{e.message}"
          Rails.logger.error "  - Error class: #{e.class}"
          Rails.logger.error "  - Backtrace: #{e.backtrace.first(3).join('\n')}"
          Rails.logger.error '  - Using empty plan limits and continuing webhook processing'
          plan_limits = {}
        end

        Rails.logger.info "📋 Plan limits result: #{plan_limits.inspect}"
        Rails.logger.info '▶️  Webhook processing continues regardless of plan limits extraction outcome...'

        # Extract values with defensive checks to prevent array->string conversion errors
        cancel_at_period_end = extract_cancel_at_period_end(subscription)
        canceled_at = extract_canceled_at(subscription)
        ended_at = extract_ended_at(subscription)

        # Log extracted values for debugging
        Rails.logger.info 'Extracted values:'
        Rails.logger.info "  - cancel_at_period_end: #{cancel_at_period_end} (class: #{cancel_at_period_end.class})"
        Rails.logger.info "  - canceled_at: #{canceled_at} (class: #{canceled_at.class})"
        Rails.logger.info "  - ended_at: #{ended_at} (class: #{ended_at.class})"

        custom_attrs.merge!(
          'plan_name' => plan_name,
          'stripe_customer_id' => stripe_customer_id,
          'subscription_status' => subscription_status,
          'current_period_end' => current_period_end,
          'subscription_ends_on' => current_period_end ? Time.at(current_period_end).strftime('%Y-%m-%d') : nil,
          'cancel_at_period_end' => cancel_at_period_end,
          'canceled_at' => canceled_at,
          'ended_at' => ended_at
        )

        # Update account limits directly from billing provider metadata (dynamic)
        if plan_limits.present?
          # Dynamically assign all limits from billing provider metadata
          account.limits = plan_limits
          Rails.logger.info "Updated account limits from billing provider metadata: #{plan_limits}"
        end

        # If subscription is being cancelled (cancel_at_period_end = true),
        # update subscription_ends_on to the actual cancellation date
        if cancel_at_period_end && extract_cancel_at(subscription)
          cancel_at = extract_cancel_at(subscription)
          Rails.logger.info "Cancellation data - cancel_at: #{cancel_at} (class: #{cancel_at.class})"

          if cancel_at.present? && cancel_at.respond_to?(:to_i)
            cancel_date = Time.at(cancel_at.to_i)
            custom_attrs['subscription_ends_on'] = cancel_date.strftime('%Y-%m-%d')
            Rails.logger.info "Subscription cancellation detected - ends on: #{custom_attrs['subscription_ends_on']}"
          end
        end

        Rails.logger.info 'Step 4: Updating account with custom attributes'
        Rails.logger.info "New custom_attrs: #{custom_attrs}"

        account.update!(custom_attributes: custom_attrs)
        Rails.logger.info 'Step 5: Account updated successfully'
        Rails.logger.info '✅ UPDATE ACCOUNT SUBSCRIPTION DATA - COMPLETED SUCCESSFULLY'
        Rails.logger.info '   - Webhook processing succeeded regardless of any metadata extraction issues'
      end

      # Syncs account features based on subscription
      def sync_account_features(account, subscription)
        plan_name = extract_plan_name_from_subscription(subscription)
        Billing::SyncAccountFeaturesService.new(account, plan_name).perform if plan_name
      end

      # Updates account attributes with subscription data and cancellation tracking
      def update_account_attributes(account, subscription = nil, target_plan = 'community')
        custom_attrs = account.custom_attributes || {}

        Rails.logger.info "Updating account #{account.id} attributes to plan: #{target_plan}"
        Rails.logger.info "Existing custom_attributes: #{custom_attrs}"

        # Update plan and subscription status
        custom_attrs.merge!(
          'plan_name' => target_plan,
          'subscription_status' => Billing::SubscriptionStatuses::INACTIVE
        )

        # If subscription data is provided, extract and preserve cancellation tracking
        if subscription
          custom_attrs.merge!(
            'cancel_at_period_end' => extract_cancel_at_period_end(subscription),
            'canceled_at' => extract_canceled_at(subscription),
            'ended_at' => extract_ended_at(subscription)
          )
        end

        Rails.logger.info "Updated custom_attributes: #{custom_attrs}"

        account.update!(custom_attributes: custom_attrs)
      end

      # Updates payment status in account
      def update_payment_status(account, status)
        custom_attrs = account.custom_attributes || {}
        custom_attrs['last_payment_status'] = status
        custom_attrs['last_payment_date'] = Time.current.strftime('%Y-%m-%d')

        account.update!(custom_attributes: custom_attrs)
      end

      # Updates billing status in account
      def update_billing_status(account, status)
        custom_attrs = account.custom_attributes || {}
        custom_attrs['billing_status'] = status
        custom_attrs['billing_status_updated_at'] = Time.current.iso8601

        account.update!(custom_attributes: custom_attrs)
        Rails.logger.info "Updated billing status for account #{account.id} to: #{status}"
      rescue StandardError => e
        Rails.logger.error "Failed to update billing status for account #{account.id}: #{e.message}"
      end

      # Extract plan limits from subscription metadata
      def extract_plan_limits_from_subscription(subscription)
        Rails.logger.info '---[EXTRACT PLAN LIMITS - START]---'

        product_metadata = Billing::StripeMetadataExtractor.extract_product_metadata(subscription, with_logging: true)

        Rails.logger.info "Product metadata received from extract_product_metadata: #{product_metadata.inspect}"

        # Check if metadata is empty (Stripe objects don't have .empty? method)
        metadata_empty = product_metadata.nil? || (product_metadata.respond_to?(:keys) && product_metadata.keys.empty?)
        Rails.logger.info "Metadata is empty: #{metadata_empty}"

        limits = self.class.limits_from_billing_provider_metadata(product_metadata)

        Rails.logger.info "Plan limits extracted: #{limits.inspect}"
        Rails.logger.info '---[EXTRACT PLAN LIMITS - COMPLETED]---'

        limits
      end

      # Extracts plan name from subscription metadata or price lookup
      def extract_plan_name_from_subscription(subscription)
        # Try to get from metadata first
        plan_name = if subscription.is_a?(Hash)
                      subscription.dig('metadata', 'plan_name')
                    else
                      subscription.metadata['plan_name']
                    end
        return plan_name if plan_name.present?

        # Fallback: lookup by price ID
        # handle both hash-style data (from direct webhook payloads) and object-style data (from Stripe API calls).
        price_id = if subscription.is_a?(Hash)
                     subscription.dig('items', 'data', 0, 'price', 'id')
                   else
                     subscription.items&.data&.first&.price&.id
                   end
        return nil unless price_id

        self.class.plan_name_by_price_id(price_id)
      end

      # Extracts cancel_at_period_end from subscription
      def extract_cancel_at_period_end(subscription)
        if subscription.is_a?(Hash)
          subscription['cancel_at_period_end'] || false
        else
          subscription.cancel_at_period_end || false
        end
      end

      # Extracts canceled_at timestamp from subscription
      def extract_canceled_at(subscription)
        if subscription.is_a?(Hash)
          subscription['canceled_at']
        else
          subscription.canceled_at
        end
      end

      # Extracts ended_at timestamp from subscription
      def extract_ended_at(subscription)
        if subscription.is_a?(Hash)
          subscription['ended_at']
        else
          subscription.ended_at
        end
      end

      # Extracts cancel_at timestamp from subscription
      def extract_cancel_at(subscription)
        if subscription.is_a?(Hash)
          subscription['cancel_at']
        else
          subscription.cancel_at
        end
      end

      # Helper methods for webhook responses
      def success_response(message)
        { success: true, message: message }
      end

      def failure_response(message)
        { success: false, error: message }
      end
    end
  end
end