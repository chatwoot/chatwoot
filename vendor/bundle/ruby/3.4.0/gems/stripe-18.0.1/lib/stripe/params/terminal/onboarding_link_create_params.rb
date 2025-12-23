# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class OnboardingLinkCreateParams < ::Stripe::RequestParams
      class LinkOptions < ::Stripe::RequestParams
        class AppleTermsAndConditions < ::Stripe::RequestParams
          # Whether the link should also support users relinking their Apple account.
          attr_accessor :allow_relinking
          # The business name of the merchant accepting Apple's Terms and Conditions.
          attr_accessor :merchant_display_name

          def initialize(allow_relinking: nil, merchant_display_name: nil)
            @allow_relinking = allow_relinking
            @merchant_display_name = merchant_display_name
          end
        end
        # The options associated with the Apple Terms and Conditions link type.
        attr_accessor :apple_terms_and_conditions

        def initialize(apple_terms_and_conditions: nil)
          @apple_terms_and_conditions = apple_terms_and_conditions
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Specific fields needed to generate the desired link type.
      attr_accessor :link_options
      # The type of link being generated.
      attr_accessor :link_type
      # Stripe account ID to generate the link for.
      attr_accessor :on_behalf_of

      def initialize(expand: nil, link_options: nil, link_type: nil, on_behalf_of: nil)
        @expand = expand
        @link_options = link_options
        @link_type = link_type
        @on_behalf_of = on_behalf_of
      end
    end
  end
end
