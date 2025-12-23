# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # This is an object representing a person associated with a Stripe account.
  #
  # A platform can only access a subset of data in a person for an account where [account.controller.requirement_collection](https://docs.stripe.com/api/accounts/object#account_object-controller-requirement_collection) is `stripe`, which includes Standard and Express accounts, after creating an Account Link or Account Session to start Connect onboarding.
  #
  # See the [Standard onboarding](https://docs.stripe.com/connect/standard-accounts) or [Express onboarding](https://docs.stripe.com/connect/express-accounts) documentation for information about prefilling information and account onboarding steps. Learn more about [handling identity verification with the API](https://docs.stripe.com/connect/handling-api-verification#person-information).
  class Person < APIResource
    include Stripe::APIOperations::Save

    OBJECT_NAME = "person"
    def self.object_name
      "person"
    end

    class AdditionalTosAcceptances < ::Stripe::StripeObject
      class Account < ::Stripe::StripeObject
        # The Unix timestamp marking when the legal guardian accepted the service agreement.
        attr_reader :date
        # The IP address from which the legal guardian accepted the service agreement.
        attr_reader :ip
        # The user agent of the browser from which the legal guardian accepted the service agreement.
        attr_reader :user_agent

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Details on the legal guardian's acceptance of the main Stripe service agreement.
      attr_reader :account

      def self.inner_class_types
        @inner_class_types = { account: Account }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Address < ::Stripe::StripeObject
      # City, district, suburb, town, or village.
      attr_reader :city
      # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
      attr_reader :country
      # Address line 1, such as the street, PO Box, or company name.
      attr_reader :line1
      # Address line 2, such as the apartment, suite, unit, or building.
      attr_reader :line2
      # ZIP or postal code.
      attr_reader :postal_code
      # State, county, province, or region.
      attr_reader :state

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AddressKana < ::Stripe::StripeObject
      # City/Ward.
      attr_reader :city
      # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
      attr_reader :country
      # Block/Building number.
      attr_reader :line1
      # Building details.
      attr_reader :line2
      # ZIP or postal code.
      attr_reader :postal_code
      # Prefecture.
      attr_reader :state
      # Town/cho-me.
      attr_reader :town

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AddressKanji < ::Stripe::StripeObject
      # City/Ward.
      attr_reader :city
      # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
      attr_reader :country
      # Block/Building number.
      attr_reader :line1
      # Building details.
      attr_reader :line2
      # ZIP or postal code.
      attr_reader :postal_code
      # Prefecture.
      attr_reader :state
      # Town/cho-me.
      attr_reader :town

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Dob < ::Stripe::StripeObject
      # The day of birth, between 1 and 31.
      attr_reader :day
      # The month of birth, between 1 and 12.
      attr_reader :month
      # The four-digit year of birth.
      attr_reader :year

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
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
      # Fields that need to be collected to keep the person's account enabled. If not collected by the account's `future_requirements[current_deadline]`, these fields will transition to the main `requirements` hash, and may immediately become `past_due`, but the account may also be given a grace period depending on the account's enablement state prior to transition.
      attr_reader :currently_due
      # Fields that are `currently_due` and need to be collected again because validation or verification failed.
      attr_reader :errors
      # Fields you must collect when all thresholds are reached. As they become required, they appear in `currently_due` as well, and the account's `future_requirements[current_deadline]` becomes set.
      attr_reader :eventually_due
      # Fields that weren't collected by the account's `requirements.current_deadline`. These fields need to be collected to enable the person's account. New fields will never appear here; `future_requirements.past_due` will always be a subset of `requirements.past_due`.
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

    class RegisteredAddress < ::Stripe::StripeObject
      # City, district, suburb, town, or village.
      attr_reader :city
      # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
      attr_reader :country
      # Address line 1, such as the street, PO Box, or company name.
      attr_reader :line1
      # Address line 2, such as the apartment, suite, unit, or building.
      attr_reader :line2
      # ZIP or postal code.
      attr_reader :postal_code
      # State, county, province, or region.
      attr_reader :state

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Relationship < ::Stripe::StripeObject
      # Whether the person is the authorizer of the account's representative.
      attr_reader :authorizer
      # Whether the person is a director of the account's legal entity. Directors are typically members of the governing board of the company, or responsible for ensuring the company meets its regulatory obligations.
      attr_reader :director
      # Whether the person has significant responsibility to control, manage, or direct the organization.
      attr_reader :executive
      # Whether the person is the legal guardian of the account's representative.
      attr_reader :legal_guardian
      # Whether the person is an owner of the account’s legal entity.
      attr_reader :owner
      # The percent owned by the person of the account's legal entity.
      attr_reader :percent_ownership
      # Whether the person is authorized as the primary representative of the account. This is the person nominated by the business to provide information about themselves, and general information about the account. There can only be one representative at any given time. At the time the account is created, this person should be set to the person responsible for opening the account.
      attr_reader :representative
      # The person's title (e.g., CEO, Support Engineer).
      attr_reader :title

      def self.inner_class_types
        @inner_class_types = {}
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
      # Fields that need to be collected to keep the person's account enabled. If not collected by the account's `current_deadline`, these fields appear in `past_due` as well, and the account is disabled.
      attr_reader :currently_due
      # Fields that are `currently_due` and need to be collected again because validation or verification failed.
      attr_reader :errors
      # Fields you must collect when all thresholds are reached. As they become required, they appear in `currently_due` as well, and the account's `current_deadline` becomes set.
      attr_reader :eventually_due
      # Fields that weren't collected by the account's `current_deadline`. These fields need to be collected to enable the person's account.
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

    class UsCfpbData < ::Stripe::StripeObject
      class EthnicityDetails < ::Stripe::StripeObject
        # The persons ethnicity
        attr_reader :ethnicity
        # Please specify your origin, when other is selected.
        attr_reader :ethnicity_other

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RaceDetails < ::Stripe::StripeObject
        # The persons race.
        attr_reader :race
        # Please specify your race, when other is selected.
        attr_reader :race_other

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The persons ethnicity details
      attr_reader :ethnicity_details
      # The persons race details
      attr_reader :race_details
      # The persons self-identified gender
      attr_reader :self_identified_gender

      def self.inner_class_types
        @inner_class_types = { ethnicity_details: EthnicityDetails, race_details: RaceDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Verification < ::Stripe::StripeObject
      class AdditionalDocument < ::Stripe::StripeObject
        # The back of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`.
        attr_reader :back
        # A user-displayable string describing the verification state of this document. For example, if a document is uploaded and the picture is too fuzzy, this may say "Identity document is too unclear to read".
        attr_reader :details
        # One of `document_corrupt`, `document_country_not_supported`, `document_expired`, `document_failed_copy`, `document_failed_other`, `document_failed_test_mode`, `document_fraudulent`, `document_failed_greyscale`, `document_incomplete`, `document_invalid`, `document_manipulated`, `document_missing_back`, `document_missing_front`, `document_not_readable`, `document_not_uploaded`, `document_photo_mismatch`, `document_too_large`, or `document_type_not_supported`. A machine-readable code specifying the verification state for this document.
        attr_reader :details_code
        # The front of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`.
        attr_reader :front

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Document < ::Stripe::StripeObject
        # The back of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`.
        attr_reader :back
        # A user-displayable string describing the verification state of this document. For example, if a document is uploaded and the picture is too fuzzy, this may say "Identity document is too unclear to read".
        attr_reader :details
        # One of `document_corrupt`, `document_country_not_supported`, `document_expired`, `document_failed_copy`, `document_failed_other`, `document_failed_test_mode`, `document_fraudulent`, `document_failed_greyscale`, `document_incomplete`, `document_invalid`, `document_manipulated`, `document_missing_back`, `document_missing_front`, `document_not_readable`, `document_not_uploaded`, `document_photo_mismatch`, `document_too_large`, or `document_type_not_supported`. A machine-readable code specifying the verification state for this document.
        attr_reader :details_code
        # The front of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`.
        attr_reader :front

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.
      attr_reader :additional_document
      # A user-displayable string describing the verification state for the person. For example, this may say "Provided identity information could not be verified".
      attr_reader :details
      # One of `document_address_mismatch`, `document_dob_mismatch`, `document_duplicate_type`, `document_id_number_mismatch`, `document_name_mismatch`, `document_nationality_mismatch`, `failed_keyed_identity`, or `failed_other`. A machine-readable code specifying the verification state for the person.
      attr_reader :details_code
      # Attribute for field document
      attr_reader :document
      # The state of verification for the person. Possible values are `unverified`, `pending`, or `verified`. Please refer [guide](https://stripe.com/docs/connect/handling-api-verification) to handle verification updates.
      attr_reader :status

      def self.inner_class_types
        @inner_class_types = { additional_document: AdditionalDocument, document: Document }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # The account the person is associated with.
    attr_reader :account
    # Attribute for field additional_tos_acceptances
    attr_reader :additional_tos_acceptances
    # Attribute for field address
    attr_reader :address
    # The Kana variation of the person's address (Japan only).
    attr_reader :address_kana
    # The Kanji variation of the person's address (Japan only).
    attr_reader :address_kanji
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Attribute for field dob
    attr_reader :dob
    # The person's email address. Also available for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `stripe`.
    attr_reader :email
    # The person's first name. Also available for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `stripe`.
    attr_reader :first_name
    # The Kana variation of the person's first name (Japan only). Also available for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `stripe`.
    attr_reader :first_name_kana
    # The Kanji variation of the person's first name (Japan only). Also available for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `stripe`.
    attr_reader :first_name_kanji
    # A list of alternate names or aliases that the person is known by. Also available for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `stripe`.
    attr_reader :full_name_aliases
    # Information about the [upcoming new requirements for this person](https://stripe.com/docs/connect/custom-accounts/future-requirements), including what information needs to be collected, and by when.
    attr_reader :future_requirements
    # The person's gender.
    attr_reader :gender
    # Unique identifier for the object.
    attr_reader :id
    # Whether the person's `id_number` was provided. True if either the full ID number was provided or if only the required part of the ID number was provided (ex. last four of an individual's SSN for the US indicated by `ssn_last_4_provided`).
    attr_reader :id_number_provided
    # Whether the person's `id_number_secondary` was provided.
    attr_reader :id_number_secondary_provided
    # The person's last name. Also available for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `stripe`.
    attr_reader :last_name
    # The Kana variation of the person's last name (Japan only). Also available for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `stripe`.
    attr_reader :last_name_kana
    # The Kanji variation of the person's last name (Japan only). Also available for accounts where [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `stripe`.
    attr_reader :last_name_kanji
    # The person's maiden name.
    attr_reader :maiden_name
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # The country where the person is a national.
    attr_reader :nationality
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The person's phone number.
    attr_reader :phone
    # Indicates if the person or any of their representatives, family members, or other closely related persons, declares that they hold or have held an important public job or function, in any jurisdiction.
    attr_reader :political_exposure
    # Attribute for field registered_address
    attr_reader :registered_address
    # Attribute for field relationship
    attr_reader :relationship
    # Information about the requirements for this person, including what information needs to be collected, and by when.
    attr_reader :requirements
    # Whether the last four digits of the person's Social Security number have been provided (U.S. only).
    attr_reader :ssn_last_4_provided
    # Demographic data related to the person.
    attr_reader :us_cfpb_data
    # Attribute for field verification
    attr_reader :verification
    # Always true for a deleted object
    attr_reader :deleted

    def resource_url
      if !respond_to?(:account) || account.nil?
        raise NotImplementedError,
              "Persons cannot be accessed without an account ID."
      end
      "#{Account.resource_url}/#{CGI.escape(account)}/persons/#{CGI.escape(id)}"
    end

    def self.retrieve(_id, _opts = {})
      raise NotImplementedError,
            "Persons cannot be retrieved without an account ID. Retrieve a " \
            "person using `Account.retrieve_person('account_id', 'person_id')`"
    end

    def self.update(_id, _params = nil, _opts = nil)
      raise NotImplementedError,
            "Persons cannot be updated without an account ID. Update a " \
            "person using `Account.update_person('account_id', 'person_id', " \
            "update_params)`"
    end

    def self.inner_class_types
      @inner_class_types = {
        additional_tos_acceptances: AdditionalTosAcceptances,
        address: Address,
        address_kana: AddressKana,
        address_kanji: AddressKanji,
        dob: Dob,
        future_requirements: FutureRequirements,
        registered_address: RegisteredAddress,
        relationship: Relationship,
        requirements: Requirements,
        us_cfpb_data: UsCfpbData,
        verification: Verification,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
