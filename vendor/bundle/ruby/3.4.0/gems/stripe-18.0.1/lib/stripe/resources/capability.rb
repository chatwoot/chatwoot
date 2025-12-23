# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # This is an object representing a capability for a Stripe account.
  #
  # Related guide: [Account capabilities](https://stripe.com/docs/connect/account-capabilities)
  class Capability < APIResource
    include Stripe::APIOperations::Save

    OBJECT_NAME = "capability"
    def self.object_name
      "capability"
    end

    class FutureRequirements < ::Stripe::StripeObject
      class Alternative < ::Stripe::StripeObject
        # Fields that can be provided to satisfy all fields in `original_fields_due`.
        attr_reader :alternative_fields_due
        # Fields that are due and can be satisfied by providing all fields in `alternative_fields_due`.
        attr_reader :original_fields_due

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Error < ::Stripe::StripeObject
        # The code for the type of error.
        attr_reader :code
        # An informative message that indicates the error type and provides additional details about the error.
        attr_reader :reason
        # The specific user onboarding requirement field (in the requirements hash) that needs to be resolved.
        attr_reader :requirement

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Fields that are due and can be satisfied by providing the corresponding alternative fields instead.
      attr_reader :alternatives
      # Date on which `future_requirements` becomes the main `requirements` hash and `future_requirements` becomes empty. After the transition, `currently_due` requirements may immediately become `past_due`, but the account may also be given a grace period depending on the capability's enablement state prior to transitioning.
      attr_reader :current_deadline
      # Fields that need to be collected to keep the capability enabled. If not collected by `future_requirements[current_deadline]`, these fields will transition to the main `requirements` hash.
      attr_reader :currently_due
      # This is typed as an enum for consistency with `requirements.disabled_reason`, but it safe to assume `future_requirements.disabled_reason` is null because fields in `future_requirements` will never disable the account.
      attr_reader :disabled_reason
      # Fields that are `currently_due` and need to be collected again because validation or verification failed.
      attr_reader :errors
      # Fields you must collect when all thresholds are reached. As they become required, they appear in `currently_due` as well.
      attr_reader :eventually_due
      # Fields that weren't collected by `requirements.current_deadline`. These fields need to be collected to enable the capability on the account. New fields will never appear here; `future_requirements.past_due` will always be a subset of `requirements.past_due`.
      attr_reader :past_due
      # Fields that might become required depending on the results of verification or review. It's an empty array unless an asynchronous verification is pending. If verification fails, these fields move to `eventually_due` or `currently_due`. Fields might appear in `eventually_due` or `currently_due` and in `pending_verification` if verification fails but another verification is still pending.
      attr_reader :pending_verification

      def self.inner_class_types
        @inner_class_types = { alternatives: Alternative, errors: Error }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Requirements < ::Stripe::StripeObject
      class Alternative < ::Stripe::StripeObject
        # Fields that can be provided to satisfy all fields in `original_fields_due`.
        attr_reader :alternative_fields_due
        # Fields that are due and can be satisfied by providing all fields in `alternative_fields_due`.
        attr_reader :original_fields_due

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Error < ::Stripe::StripeObject
        # The code for the type of error.
        attr_reader :code
        # An informative message that indicates the error type and provides additional details about the error.
        attr_reader :reason
        # The specific user onboarding requirement field (in the requirements hash) that needs to be resolved.
        attr_reader :requirement

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Fields that are due and can be satisfied by providing the corresponding alternative fields instead.
      attr_reader :alternatives
      # The date by which all required account information must be both submitted and verified. This includes fields listed in `currently_due` as well as those in `pending_verification`. If any required information is missing or unverified by this date, the account may be disabled. Note that `current_deadline` may change if additional `currently_due` requirements are requested.
      attr_reader :current_deadline
      # Fields that need to be collected to keep the capability enabled. If not collected by `current_deadline`, these fields appear in `past_due` as well, and the capability is disabled.
      attr_reader :currently_due
      # Description of why the capability is disabled. [Learn more about handling verification issues](https://stripe.com/docs/connect/handling-api-verification).
      attr_reader :disabled_reason
      # Fields that are `currently_due` and need to be collected again because validation or verification failed.
      attr_reader :errors
      # Fields you must collect when all thresholds are reached. As they become required, they appear in `currently_due` as well, and `current_deadline` becomes set.
      attr_reader :eventually_due
      # Fields that weren't collected by `current_deadline`. These fields need to be collected to enable the capability on the account.
      attr_reader :past_due
      # Fields that might become required depending on the results of verification or review. It's an empty array unless an asynchronous verification is pending. If verification fails, these fields move to `eventually_due`, `currently_due`, or `past_due`. Fields might appear in `eventually_due`, `currently_due`, or `past_due` and in `pending_verification` if verification fails but another verification is still pending.
      attr_reader :pending_verification

      def self.inner_class_types
        @inner_class_types = { alternatives: Alternative, errors: Error }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # The account for which the capability enables functionality.
    attr_reader :account
    # Attribute for field future_requirements
    attr_reader :future_requirements
    # The identifier for the capability.
    attr_reader :id
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Whether the capability has been requested.
    attr_reader :requested
    # Time at which the capability was requested. Measured in seconds since the Unix epoch.
    attr_reader :requested_at
    # Attribute for field requirements
    attr_reader :requirements
    # The status of the capability.
    attr_reader :status

    def resource_url
      if !respond_to?(:account) || account.nil?
        raise NotImplementedError,
              "Capabilities cannot be accessed without an account ID."
      end
      "#{Account.resource_url}/#{CGI.escape(account)}/capabilities" \
        "/#{CGI.escape(id)}"
    end

    def self.retrieve(_id, _opts = {})
      raise NotImplementedError,
            "Capabilities cannot be retrieve without an account ID. " \
            "Retrieve a capability using Account.retrieve_capability(" \
            "'account_id', 'capability_id')`"
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Capabilities cannot be updated without an account ID. Update a " \
            "capability using `Account.update_capability('account_id', " \
            "'capability_id', update_params)`"
    end

    def self.inner_class_types
      @inner_class_types = { future_requirements: FutureRequirements, requirements: Requirements }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
