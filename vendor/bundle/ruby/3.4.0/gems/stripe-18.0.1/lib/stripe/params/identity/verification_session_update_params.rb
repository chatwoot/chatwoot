# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Identity
    class VerificationSessionUpdateParams < ::Stripe::RequestParams
      class Options < ::Stripe::RequestParams
        class Document < ::Stripe::RequestParams
          # Array of strings of allowed identity document types. If the provided identity document isn’t one of the allowed types, the verification check will fail with a document_type_not_allowed error code.
          attr_accessor :allowed_types
          # Collect an ID number and perform an [ID number check](https://stripe.com/docs/identity/verification-checks?type=id-number) with the document’s extracted name and date of birth.
          attr_accessor :require_id_number
          # Disable image uploads, identity document images have to be captured using the device’s camera.
          attr_accessor :require_live_capture
          # Capture a face image and perform a [selfie check](https://stripe.com/docs/identity/verification-checks?type=selfie) comparing a photo ID and a picture of your user’s face. [Learn more](https://stripe.com/docs/identity/selfie).
          attr_accessor :require_matching_selfie

          def initialize(
            allowed_types: nil,
            require_id_number: nil,
            require_live_capture: nil,
            require_matching_selfie: nil
          )
            @allowed_types = allowed_types
            @require_id_number = require_id_number
            @require_live_capture = require_live_capture
            @require_matching_selfie = require_matching_selfie
          end
        end
        # Options that apply to the [document check](https://stripe.com/docs/identity/verification-checks?type=document).
        attr_accessor :document

        def initialize(document: nil)
          @document = document
        end
      end

      class ProvidedDetails < ::Stripe::RequestParams
        # Email of user being verified
        attr_accessor :email
        # Phone number of user being verified
        attr_accessor :phone

        def initialize(email: nil, phone: nil)
          @email = email
          @phone = phone
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # A set of options for the session’s verification checks.
      attr_accessor :options
      # Details provided about the user being verified. These details may be shown to the user.
      attr_accessor :provided_details
      # The type of [verification check](https://stripe.com/docs/identity/verification-checks) to be performed.
      attr_accessor :type

      def initialize(expand: nil, metadata: nil, options: nil, provided_details: nil, type: nil)
        @expand = expand
        @metadata = metadata
        @options = options
        @provided_details = provided_details
        @type = type
      end
    end
  end
end
