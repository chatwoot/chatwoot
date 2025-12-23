# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    # Returns redirect links used for onboarding onto Tap to Pay on iPhone.
    class OnboardingLink < APIResource
      extend Stripe::APIOperations::Create

      OBJECT_NAME = "terminal.onboarding_link"
      def self.object_name
        "terminal.onboarding_link"
      end

      class LinkOptions < ::Stripe::StripeObject
        class AppleTermsAndConditions < ::Stripe::StripeObject
          # Whether the link should also support users relinking their Apple account.
          attr_reader :allow_relinking
          # The business name of the merchant accepting Apple's Terms and Conditions.
          attr_reader :merchant_display_name

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The options associated with the Apple Terms and Conditions link type.
        attr_reader :apple_terms_and_conditions

        def self.inner_class_types
          @inner_class_types = { apple_terms_and_conditions: AppleTermsAndConditions }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Link type options associated with the current onboarding link object.
      attr_reader :link_options
      # The type of link being generated.
      attr_reader :link_type
      # Attribute for field object
      attr_reader :object
      # Stripe account ID to generate the link for.
      attr_reader :on_behalf_of
      # The link passed back to the user for their onboarding.
      attr_reader :redirect_url

      # Creates a new OnboardingLink object that contains a redirect_url used for onboarding onto Tap to Pay on iPhone.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/terminal/onboarding_links",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { link_options: LinkOptions }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
