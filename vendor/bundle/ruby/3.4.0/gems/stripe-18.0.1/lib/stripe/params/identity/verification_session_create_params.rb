# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Identity
    class VerificationSessionCreateParams < ::Stripe::RequestParams
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

      class RelatedPerson < ::Stripe::RequestParams
        # A token representing a connected account. If provided, the person parameter is also required and must be associated with the account.
        attr_accessor :account
        # A token referencing a Person resource that this verification is being used to verify.
        attr_accessor :person

        def initialize(account: nil, person: nil)
          @account = account
          @person = person
        end
      end
      # A string to reference this user. This can be a customer ID, a session ID, or similar, and can be used to reconcile this verification with your internal systems.
      attr_accessor :client_reference_id
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # A set of options for the session’s verification checks.
      attr_accessor :options
      # Details provided about the user being verified. These details may be shown to the user.
      attr_accessor :provided_details
      # Customer ID
      attr_accessor :related_customer
      # Tokens referencing a Person resource and it's associated account.
      attr_accessor :related_person
      # The URL that the user will be redirected to upon completing the verification flow.
      attr_accessor :return_url
      # The type of [verification check](https://stripe.com/docs/identity/verification-checks) to be performed. You must provide a `type` if not passing `verification_flow`.
      attr_accessor :type
      # The ID of a verification flow from the Dashboard. See https://docs.stripe.com/identity/verification-flows.
      attr_accessor :verification_flow

      def initialize(
        client_reference_id: nil,
        expand: nil,
        metadata: nil,
        options: nil,
        provided_details: nil,
        related_customer: nil,
        related_person: nil,
        return_url: nil,
        type: nil,
        verification_flow: nil
      )
        @client_reference_id = client_reference_id
        @expand = expand
        @metadata = metadata
        @options = options
        @provided_details = provided_details
        @related_customer = related_customer
        @related_person = related_person
        @return_url = return_url
        @type = type
        @verification_flow = verification_flow
      end
    end
  end
end
