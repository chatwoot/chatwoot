# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TokenCreateParams < ::Stripe::RequestParams
    class Account < ::Stripe::RequestParams
      class Company < ::Stripe::RequestParams
        class Address < ::Stripe::RequestParams
          # City, district, suburb, town, or village.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Address line 1, such as the street, PO Box, or company name.
          attr_accessor :line1
          # Address line 2, such as the apartment, suite, unit, or building.
          attr_accessor :line2
          # ZIP or postal code.
          attr_accessor :postal_code
          # State, county, province, or region.
          attr_accessor :state

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
          end
        end

        class AddressKana < ::Stripe::RequestParams
          # City or ward.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Block or building number.
          attr_accessor :line1
          # Building details.
          attr_accessor :line2
          # Postal code.
          attr_accessor :postal_code
          # Prefecture.
          attr_accessor :state
          # Town or cho-me.
          attr_accessor :town

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil,
            town: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
            @town = town
          end
        end

        class AddressKanji < ::Stripe::RequestParams
          # City or ward.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Block or building number.
          attr_accessor :line1
          # Building details.
          attr_accessor :line2
          # Postal code.
          attr_accessor :postal_code
          # Prefecture.
          attr_accessor :state
          # Town or cho-me.
          attr_accessor :town

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil,
            town: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
            @town = town
          end
        end

        class DirectorshipDeclaration < ::Stripe::RequestParams
          # The Unix timestamp marking when the directorship declaration attestation was made.
          attr_accessor :date
          # The IP address from which the directorship declaration attestation was made.
          attr_accessor :ip
          # The user agent of the browser from which the directorship declaration attestation was made.
          attr_accessor :user_agent

          def initialize(date: nil, ip: nil, user_agent: nil)
            @date = date
            @ip = ip
            @user_agent = user_agent
          end
        end

        class OwnershipDeclaration < ::Stripe::RequestParams
          # The Unix timestamp marking when the beneficial owner attestation was made.
          attr_accessor :date
          # The IP address from which the beneficial owner attestation was made.
          attr_accessor :ip
          # The user agent of the browser from which the beneficial owner attestation was made.
          attr_accessor :user_agent

          def initialize(date: nil, ip: nil, user_agent: nil)
            @date = date
            @ip = ip
            @user_agent = user_agent
          end
        end

        class RegistrationDate < ::Stripe::RequestParams
          # The day of registration, between 1 and 31.
          attr_accessor :day
          # The month of registration, between 1 and 12.
          attr_accessor :month
          # The four-digit year of registration.
          attr_accessor :year

          def initialize(day: nil, month: nil, year: nil)
            @day = day
            @month = month
            @year = year
          end
        end

        class RepresentativeDeclaration < ::Stripe::RequestParams
          # The Unix timestamp marking when the representative declaration attestation was made.
          attr_accessor :date
          # The IP address from which the representative declaration attestation was made.
          attr_accessor :ip
          # The user agent of the browser from which the representative declaration attestation was made.
          attr_accessor :user_agent

          def initialize(date: nil, ip: nil, user_agent: nil)
            @date = date
            @ip = ip
            @user_agent = user_agent
          end
        end

        class Verification < ::Stripe::RequestParams
          class Document < ::Stripe::RequestParams
            # The back of a document returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `additional_verification`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
            attr_accessor :back
            # The front of a document returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `additional_verification`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
            attr_accessor :front

            def initialize(back: nil, front: nil)
              @back = back
              @front = front
            end
          end
          # A document verifying the business.
          attr_accessor :document

          def initialize(document: nil)
            @document = document
          end
        end
        # The company's primary address.
        attr_accessor :address
        # The Kana variation of the company's primary address (Japan only).
        attr_accessor :address_kana
        # The Kanji variation of the company's primary address (Japan only).
        attr_accessor :address_kanji
        # Whether the company's directors have been provided. Set this Boolean to `true` after creating all the company's directors with [the Persons API](/api/persons) for accounts with a `relationship.director` requirement. This value is not automatically set to `true` after creating directors, so it needs to be updated to indicate all directors have been provided.
        attr_accessor :directors_provided
        # This hash is used to attest that the directors information provided to Stripe is both current and correct.
        attr_accessor :directorship_declaration
        # Whether the company's executives have been provided. Set this Boolean to `true` after creating all the company's executives with [the Persons API](/api/persons) for accounts with a `relationship.executive` requirement.
        attr_accessor :executives_provided
        # The export license ID number of the company, also referred as Import Export Code (India only).
        attr_accessor :export_license_id
        # The purpose code to use for export transactions (India only).
        attr_accessor :export_purpose_code
        # The company's legal name.
        attr_accessor :name
        # The Kana variation of the company's legal name (Japan only).
        attr_accessor :name_kana
        # The Kanji variation of the company's legal name (Japan only).
        attr_accessor :name_kanji
        # Whether the company's owners have been provided. Set this Boolean to `true` after creating all the company's owners with [the Persons API](/api/persons) for accounts with a `relationship.owner` requirement.
        attr_accessor :owners_provided
        # This hash is used to attest that the beneficial owner information provided to Stripe is both current and correct.
        attr_accessor :ownership_declaration
        # Whether the user described by the data in the token has been shown the Ownership Declaration and indicated that it is correct.
        attr_accessor :ownership_declaration_shown_and_signed
        # This value is used to determine if a business is exempt from providing ultimate beneficial owners. See [this support article](https://support.stripe.com/questions/exemption-from-providing-ownership-details) and [changelog](https://docs.stripe.com/changelog/acacia/2025-01-27/ownership-exemption-reason-accounts-api) for more details.
        attr_accessor :ownership_exemption_reason
        # The company's phone number (used for verification).
        attr_accessor :phone
        # When the business was incorporated or registered.
        attr_accessor :registration_date
        # The identification number given to a company when it is registered or incorporated, if distinct from the identification number used for filing taxes. (Examples are the CIN for companies and LLP IN for partnerships in India, and the Company Registration Number in Hong Kong).
        attr_accessor :registration_number
        # This hash is used to attest that the representative is authorized to act as the representative of their legal entity.
        attr_accessor :representative_declaration
        # The category identifying the legal structure of the company or legal entity. See [Business structure](/connect/identity-verification#business-structure) for more details. Pass an empty string to unset this value.
        attr_accessor :structure
        # The business ID number of the company, as appropriate for the company’s country. (Examples are an Employer ID Number in the U.S., a Business Number in Canada, or a Company Number in the UK.)
        attr_accessor :tax_id
        # The jurisdiction in which the `tax_id` is registered (Germany-based companies only).
        attr_accessor :tax_id_registrar
        # The VAT number of the company.
        attr_accessor :vat_id
        # Information on the verification state of the company.
        attr_accessor :verification

        def initialize(
          address: nil,
          address_kana: nil,
          address_kanji: nil,
          directors_provided: nil,
          directorship_declaration: nil,
          executives_provided: nil,
          export_license_id: nil,
          export_purpose_code: nil,
          name: nil,
          name_kana: nil,
          name_kanji: nil,
          owners_provided: nil,
          ownership_declaration: nil,
          ownership_declaration_shown_and_signed: nil,
          ownership_exemption_reason: nil,
          phone: nil,
          registration_date: nil,
          registration_number: nil,
          representative_declaration: nil,
          structure: nil,
          tax_id: nil,
          tax_id_registrar: nil,
          vat_id: nil,
          verification: nil
        )
          @address = address
          @address_kana = address_kana
          @address_kanji = address_kanji
          @directors_provided = directors_provided
          @directorship_declaration = directorship_declaration
          @executives_provided = executives_provided
          @export_license_id = export_license_id
          @export_purpose_code = export_purpose_code
          @name = name
          @name_kana = name_kana
          @name_kanji = name_kanji
          @owners_provided = owners_provided
          @ownership_declaration = ownership_declaration
          @ownership_declaration_shown_and_signed = ownership_declaration_shown_and_signed
          @ownership_exemption_reason = ownership_exemption_reason
          @phone = phone
          @registration_date = registration_date
          @registration_number = registration_number
          @representative_declaration = representative_declaration
          @structure = structure
          @tax_id = tax_id
          @tax_id_registrar = tax_id_registrar
          @vat_id = vat_id
          @verification = verification
        end
      end

      class Individual < ::Stripe::RequestParams
        class Address < ::Stripe::RequestParams
          # City, district, suburb, town, or village.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Address line 1, such as the street, PO Box, or company name.
          attr_accessor :line1
          # Address line 2, such as the apartment, suite, unit, or building.
          attr_accessor :line2
          # ZIP or postal code.
          attr_accessor :postal_code
          # State, county, province, or region.
          attr_accessor :state

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
          end
        end

        class AddressKana < ::Stripe::RequestParams
          # City or ward.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Block or building number.
          attr_accessor :line1
          # Building details.
          attr_accessor :line2
          # Postal code.
          attr_accessor :postal_code
          # Prefecture.
          attr_accessor :state
          # Town or cho-me.
          attr_accessor :town

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil,
            town: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
            @town = town
          end
        end

        class AddressKanji < ::Stripe::RequestParams
          # City or ward.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Block or building number.
          attr_accessor :line1
          # Building details.
          attr_accessor :line2
          # Postal code.
          attr_accessor :postal_code
          # Prefecture.
          attr_accessor :state
          # Town or cho-me.
          attr_accessor :town

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil,
            town: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
            @town = town
          end
        end

        class Dob < ::Stripe::RequestParams
          # The day of birth, between 1 and 31.
          attr_accessor :day
          # The month of birth, between 1 and 12.
          attr_accessor :month
          # The four-digit year of birth.
          attr_accessor :year

          def initialize(day: nil, month: nil, year: nil)
            @day = day
            @month = month
            @year = year
          end
        end

        class RegisteredAddress < ::Stripe::RequestParams
          # City, district, suburb, town, or village.
          attr_accessor :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_accessor :country
          # Address line 1, such as the street, PO Box, or company name.
          attr_accessor :line1
          # Address line 2, such as the apartment, suite, unit, or building.
          attr_accessor :line2
          # ZIP or postal code.
          attr_accessor :postal_code
          # State, county, province, or region.
          attr_accessor :state

          def initialize(
            city: nil,
            country: nil,
            line1: nil,
            line2: nil,
            postal_code: nil,
            state: nil
          )
            @city = city
            @country = country
            @line1 = line1
            @line2 = line2
            @postal_code = postal_code
            @state = state
          end
        end

        class Relationship < ::Stripe::RequestParams
          # Whether the person is a director of the account's legal entity. Directors are typically members of the governing board of the company, or responsible for ensuring the company meets its regulatory obligations.
          attr_accessor :director
          # Whether the person has significant responsibility to control, manage, or direct the organization.
          attr_accessor :executive
          # Whether the person is an owner of the account’s legal entity.
          attr_accessor :owner
          # The percent owned by the person of the account's legal entity.
          attr_accessor :percent_ownership
          # The person's title (e.g., CEO, Support Engineer).
          attr_accessor :title

          def initialize(
            director: nil,
            executive: nil,
            owner: nil,
            percent_ownership: nil,
            title: nil
          )
            @director = director
            @executive = executive
            @owner = owner
            @percent_ownership = percent_ownership
            @title = title
          end
        end

        class Verification < ::Stripe::RequestParams
          class AdditionalDocument < ::Stripe::RequestParams
            # The back of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
            attr_accessor :back
            # The front of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
            attr_accessor :front

            def initialize(back: nil, front: nil)
              @back = back
              @front = front
            end
          end

          class Document < ::Stripe::RequestParams
            # The back of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
            attr_accessor :back
            # The front of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
            attr_accessor :front

            def initialize(back: nil, front: nil)
              @back = back
              @front = front
            end
          end
          # A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.
          attr_accessor :additional_document
          # An identifying document, either a passport or local ID card.
          attr_accessor :document

          def initialize(additional_document: nil, document: nil)
            @additional_document = additional_document
            @document = document
          end
        end
        # The individual's primary address.
        attr_accessor :address
        # The Kana variation of the individual's primary address (Japan only).
        attr_accessor :address_kana
        # The Kanji variation of the individual's primary address (Japan only).
        attr_accessor :address_kanji
        # The individual's date of birth.
        attr_accessor :dob
        # The individual's email address.
        attr_accessor :email
        # The individual's first name.
        attr_accessor :first_name
        # The Kana variation of the individual's first name (Japan only).
        attr_accessor :first_name_kana
        # The Kanji variation of the individual's first name (Japan only).
        attr_accessor :first_name_kanji
        # A list of alternate names or aliases that the individual is known by.
        attr_accessor :full_name_aliases
        # The individual's gender
        attr_accessor :gender
        # The government-issued ID number of the individual, as appropriate for the representative's country. (Examples are a Social Security Number in the U.S., or a Social Insurance Number in Canada). Instead of the number itself, you can also provide a [PII token created with Stripe.js](/js/tokens/create_token?type=pii).
        attr_accessor :id_number
        # The government-issued secondary ID number of the individual, as appropriate for the representative's country, will be used for enhanced verification checks. In Thailand, this would be the laser code found on the back of an ID card. Instead of the number itself, you can also provide a [PII token created with Stripe.js](/js/tokens/create_token?type=pii).
        attr_accessor :id_number_secondary
        # The individual's last name.
        attr_accessor :last_name
        # The Kana variation of the individual's last name (Japan only).
        attr_accessor :last_name_kana
        # The Kanji variation of the individual's last name (Japan only).
        attr_accessor :last_name_kanji
        # The individual's maiden name.
        attr_accessor :maiden_name
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
        attr_accessor :metadata
        # The individual's phone number.
        attr_accessor :phone
        # Indicates if the person or any of their representatives, family members, or other closely related persons, declares that they hold or have held an important public job or function, in any jurisdiction.
        attr_accessor :political_exposure
        # The individual's registered address.
        attr_accessor :registered_address
        # Describes the person’s relationship to the account.
        attr_accessor :relationship
        # The last four digits of the individual's Social Security Number (U.S. only).
        attr_accessor :ssn_last_4
        # The individual's verification document information.
        attr_accessor :verification

        def initialize(
          address: nil,
          address_kana: nil,
          address_kanji: nil,
          dob: nil,
          email: nil,
          first_name: nil,
          first_name_kana: nil,
          first_name_kanji: nil,
          full_name_aliases: nil,
          gender: nil,
          id_number: nil,
          id_number_secondary: nil,
          last_name: nil,
          last_name_kana: nil,
          last_name_kanji: nil,
          maiden_name: nil,
          metadata: nil,
          phone: nil,
          political_exposure: nil,
          registered_address: nil,
          relationship: nil,
          ssn_last_4: nil,
          verification: nil
        )
          @address = address
          @address_kana = address_kana
          @address_kanji = address_kanji
          @dob = dob
          @email = email
          @first_name = first_name
          @first_name_kana = first_name_kana
          @first_name_kanji = first_name_kanji
          @full_name_aliases = full_name_aliases
          @gender = gender
          @id_number = id_number
          @id_number_secondary = id_number_secondary
          @last_name = last_name
          @last_name_kana = last_name_kana
          @last_name_kanji = last_name_kanji
          @maiden_name = maiden_name
          @metadata = metadata
          @phone = phone
          @political_exposure = political_exposure
          @registered_address = registered_address
          @relationship = relationship
          @ssn_last_4 = ssn_last_4
          @verification = verification
        end
      end
      # The business type.
      attr_accessor :business_type
      # Information about the company or business.
      attr_accessor :company
      # Information about the person represented by the account.
      attr_accessor :individual
      # Whether the user described by the data in the token has been shown [the Stripe Connected Account Agreement](/connect/account-tokens#stripe-connected-account-agreement). When creating an account token to create a new Connect account, this value must be `true`.
      attr_accessor :tos_shown_and_accepted

      def initialize(business_type: nil, company: nil, individual: nil, tos_shown_and_accepted: nil)
        @business_type = business_type
        @company = company
        @individual = individual
        @tos_shown_and_accepted = tos_shown_and_accepted
      end
    end

    class BankAccount < ::Stripe::RequestParams
      # The name of the person or business that owns the bank account. This field is required when attaching the bank account to a `Customer` object.
      attr_accessor :account_holder_name
      # The type of entity that holds the account. It can be `company` or `individual`. This field is required when attaching the bank account to a `Customer` object.
      attr_accessor :account_holder_type
      # The account number for the bank account, in string form. Must be a checking account.
      attr_accessor :account_number
      # The bank account type. This can only be `checking` or `savings` in most countries. In Japan, this can only be `futsu` or `toza`.
      attr_accessor :account_type
      # The country in which the bank account is located.
      attr_accessor :country
      # The currency the bank account is in. This must be a country/currency pairing that [Stripe supports.](https://stripe.com/docs/payouts)
      attr_accessor :currency
      # The ID of a Payment Method with a `type` of `us_bank_account`. The Payment Method's bank account information will be copied and returned as a Bank Account Token. This parameter is exclusive with respect to all other parameters in the `bank_account` hash. You must include the top-level `customer` parameter if the Payment Method is attached to a `Customer` object. If the Payment Method is not attached to a `Customer` object, it will be consumed and cannot be used again. You may not use Payment Methods which were created by a Setup Intent with `attach_to_self=true`.
      attr_accessor :payment_method
      # The routing number, sort code, or other country-appropriate institution number for the bank account. For US bank accounts, this is required and should be the ACH routing number, not the wire routing number. If you are providing an IBAN for `account_number`, this field is not required.
      attr_accessor :routing_number

      def initialize(
        account_holder_name: nil,
        account_holder_type: nil,
        account_number: nil,
        account_type: nil,
        country: nil,
        currency: nil,
        payment_method: nil,
        routing_number: nil
      )
        @account_holder_name = account_holder_name
        @account_holder_type = account_holder_type
        @account_number = account_number
        @account_type = account_type
        @country = country
        @currency = currency
        @payment_method = payment_method
        @routing_number = routing_number
      end
    end

    class Card < ::Stripe::RequestParams
      class Networks < ::Stripe::RequestParams
        # The customer's preferred card network for co-branded cards. Supports `cartes_bancaires`, `mastercard`, or `visa`. Selection of a network that does not apply to the card will be stored as `invalid_preference` on the card.
        attr_accessor :preferred

        def initialize(preferred: nil)
          @preferred = preferred
        end
      end
      # City / District / Suburb / Town / Village.
      attr_accessor :address_city
      # Billing address country, if provided.
      attr_accessor :address_country
      # Address line 1 (Street address / PO Box / Company name).
      attr_accessor :address_line1
      # Address line 2 (Apartment / Suite / Unit / Building).
      attr_accessor :address_line2
      # State / County / Province / Region.
      attr_accessor :address_state
      # ZIP or postal code.
      attr_accessor :address_zip
      # Required in order to add the card to an account; in all other cases, this parameter is not used. When added to an account, the card (which must be a debit card) can be used as a transfer destination for funds in this currency.
      attr_accessor :currency
      # Card security code. Highly recommended to always include this value.
      attr_accessor :cvc
      # Two-digit number representing the card's expiration month.
      attr_accessor :exp_month
      # Two- or four-digit number representing the card's expiration year.
      attr_accessor :exp_year
      # Cardholder's full name.
      attr_accessor :name
      # Contains information about card networks used to process the payment.
      attr_accessor :networks
      # The card number, as a string without any separators.
      attr_accessor :number

      def initialize(
        address_city: nil,
        address_country: nil,
        address_line1: nil,
        address_line2: nil,
        address_state: nil,
        address_zip: nil,
        currency: nil,
        cvc: nil,
        exp_month: nil,
        exp_year: nil,
        name: nil,
        networks: nil,
        number: nil
      )
        @address_city = address_city
        @address_country = address_country
        @address_line1 = address_line1
        @address_line2 = address_line2
        @address_state = address_state
        @address_zip = address_zip
        @currency = currency
        @cvc = cvc
        @exp_month = exp_month
        @exp_year = exp_year
        @name = name
        @networks = networks
        @number = number
      end
    end

    class CvcUpdate < ::Stripe::RequestParams
      # The CVC value, in string form.
      attr_accessor :cvc

      def initialize(cvc: nil)
        @cvc = cvc
      end
    end

    class Person < ::Stripe::RequestParams
      class AdditionalTosAcceptances < ::Stripe::RequestParams
        class Account < ::Stripe::RequestParams
          # The Unix timestamp marking when the account representative accepted the service agreement.
          attr_accessor :date
          # The IP address from which the account representative accepted the service agreement.
          attr_accessor :ip
          # The user agent of the browser from which the account representative accepted the service agreement.
          attr_accessor :user_agent

          def initialize(date: nil, ip: nil, user_agent: nil)
            @date = date
            @ip = ip
            @user_agent = user_agent
          end
        end
        # Details on the legal guardian's acceptance of the main Stripe service agreement.
        attr_accessor :account

        def initialize(account: nil)
          @account = account
        end
      end

      class Address < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end

      class AddressKana < ::Stripe::RequestParams
        # City or ward.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Block or building number.
        attr_accessor :line1
        # Building details.
        attr_accessor :line2
        # Postal code.
        attr_accessor :postal_code
        # Prefecture.
        attr_accessor :state
        # Town or cho-me.
        attr_accessor :town

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil,
          town: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
          @town = town
        end
      end

      class AddressKanji < ::Stripe::RequestParams
        # City or ward.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Block or building number.
        attr_accessor :line1
        # Building details.
        attr_accessor :line2
        # Postal code.
        attr_accessor :postal_code
        # Prefecture.
        attr_accessor :state
        # Town or cho-me.
        attr_accessor :town

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil,
          town: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
          @town = town
        end
      end

      class Dob < ::Stripe::RequestParams
        # The day of birth, between 1 and 31.
        attr_accessor :day
        # The month of birth, between 1 and 12.
        attr_accessor :month
        # The four-digit year of birth.
        attr_accessor :year

        def initialize(day: nil, month: nil, year: nil)
          @day = day
          @month = month
          @year = year
        end
      end

      class Documents < ::Stripe::RequestParams
        class CompanyAuthorization < ::Stripe::RequestParams
          # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
          attr_accessor :files

          def initialize(files: nil)
            @files = files
          end
        end

        class Passport < ::Stripe::RequestParams
          # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
          attr_accessor :files

          def initialize(files: nil)
            @files = files
          end
        end

        class Visa < ::Stripe::RequestParams
          # One or more document ids returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `account_requirement`.
          attr_accessor :files

          def initialize(files: nil)
            @files = files
          end
        end
        # One or more documents that demonstrate proof that this person is authorized to represent the company.
        attr_accessor :company_authorization
        # One or more documents showing the person's passport page with photo and personal data.
        attr_accessor :passport
        # One or more documents showing the person's visa required for living in the country where they are residing.
        attr_accessor :visa

        def initialize(company_authorization: nil, passport: nil, visa: nil)
          @company_authorization = company_authorization
          @passport = passport
          @visa = visa
        end
      end

      class RegisteredAddress < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end

      class Relationship < ::Stripe::RequestParams
        # Whether the person is the authorizer of the account's representative.
        attr_accessor :authorizer
        # Whether the person is a director of the account's legal entity. Directors are typically members of the governing board of the company, or responsible for ensuring the company meets its regulatory obligations.
        attr_accessor :director
        # Whether the person has significant responsibility to control, manage, or direct the organization.
        attr_accessor :executive
        # Whether the person is the legal guardian of the account's representative.
        attr_accessor :legal_guardian
        # Whether the person is an owner of the account’s legal entity.
        attr_accessor :owner
        # The percent owned by the person of the account's legal entity.
        attr_accessor :percent_ownership
        # Whether the person is authorized as the primary representative of the account. This is the person nominated by the business to provide information about themselves, and general information about the account. There can only be one representative at any given time. At the time the account is created, this person should be set to the person responsible for opening the account.
        attr_accessor :representative
        # The person's title (e.g., CEO, Support Engineer).
        attr_accessor :title

        def initialize(
          authorizer: nil,
          director: nil,
          executive: nil,
          legal_guardian: nil,
          owner: nil,
          percent_ownership: nil,
          representative: nil,
          title: nil
        )
          @authorizer = authorizer
          @director = director
          @executive = executive
          @legal_guardian = legal_guardian
          @owner = owner
          @percent_ownership = percent_ownership
          @representative = representative
          @title = title
        end
      end

      class UsCfpbData < ::Stripe::RequestParams
        class EthnicityDetails < ::Stripe::RequestParams
          # The persons ethnicity
          attr_accessor :ethnicity
          # Please specify your origin, when other is selected.
          attr_accessor :ethnicity_other

          def initialize(ethnicity: nil, ethnicity_other: nil)
            @ethnicity = ethnicity
            @ethnicity_other = ethnicity_other
          end
        end

        class RaceDetails < ::Stripe::RequestParams
          # The persons race.
          attr_accessor :race
          # Please specify your race, when other is selected.
          attr_accessor :race_other

          def initialize(race: nil, race_other: nil)
            @race = race
            @race_other = race_other
          end
        end
        # The persons ethnicity details
        attr_accessor :ethnicity_details
        # The persons race details
        attr_accessor :race_details
        # The persons self-identified gender
        attr_accessor :self_identified_gender

        def initialize(ethnicity_details: nil, race_details: nil, self_identified_gender: nil)
          @ethnicity_details = ethnicity_details
          @race_details = race_details
          @self_identified_gender = self_identified_gender
        end
      end

      class Verification < ::Stripe::RequestParams
        class AdditionalDocument < ::Stripe::RequestParams
          # The back of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :back
          # The front of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :front

          def initialize(back: nil, front: nil)
            @back = back
            @front = front
          end
        end

        class Document < ::Stripe::RequestParams
          # The back of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :back
          # The front of an ID returned by a [file upload](https://stripe.com/docs/api#create_file) with a `purpose` value of `identity_document`. The uploaded file needs to be a color image (smaller than 8,000px by 8,000px), in JPG, PNG, or PDF format, and less than 10 MB in size.
          attr_accessor :front

          def initialize(back: nil, front: nil)
            @back = back
            @front = front
          end
        end
        # A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.
        attr_accessor :additional_document
        # An identifying document, either a passport or local ID card.
        attr_accessor :document

        def initialize(additional_document: nil, document: nil)
          @additional_document = additional_document
          @document = document
        end
      end
      # Details on the legal guardian's or authorizer's acceptance of the required Stripe agreements.
      attr_accessor :additional_tos_acceptances
      # The person's address.
      attr_accessor :address
      # The Kana variation of the person's address (Japan only).
      attr_accessor :address_kana
      # The Kanji variation of the person's address (Japan only).
      attr_accessor :address_kanji
      # The person's date of birth.
      attr_accessor :dob
      # Documents that may be submitted to satisfy various informational requests.
      attr_accessor :documents
      # The person's email address.
      attr_accessor :email
      # The person's first name.
      attr_accessor :first_name
      # The Kana variation of the person's first name (Japan only).
      attr_accessor :first_name_kana
      # The Kanji variation of the person's first name (Japan only).
      attr_accessor :first_name_kanji
      # A list of alternate names or aliases that the person is known by.
      attr_accessor :full_name_aliases
      # The person's gender (International regulations require either "male" or "female").
      attr_accessor :gender
      # The person's ID number, as appropriate for their country. For example, a social security number in the U.S., social insurance number in Canada, etc. Instead of the number itself, you can also provide a [PII token provided by Stripe.js](https://docs.stripe.com/js/tokens/create_token?type=pii).
      attr_accessor :id_number
      # The person's secondary ID number, as appropriate for their country, will be used for enhanced verification checks. In Thailand, this would be the laser code found on the back of an ID card. Instead of the number itself, you can also provide a [PII token provided by Stripe.js](https://docs.stripe.com/js/tokens/create_token?type=pii).
      attr_accessor :id_number_secondary
      # The person's last name.
      attr_accessor :last_name
      # The Kana variation of the person's last name (Japan only).
      attr_accessor :last_name_kana
      # The Kanji variation of the person's last name (Japan only).
      attr_accessor :last_name_kanji
      # The person's maiden name.
      attr_accessor :maiden_name
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The country where the person is a national. Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)), or "XX" if unavailable.
      attr_accessor :nationality
      # The person's phone number.
      attr_accessor :phone
      # Indicates if the person or any of their representatives, family members, or other closely related persons, declares that they hold or have held an important public job or function, in any jurisdiction.
      attr_accessor :political_exposure
      # The person's registered address.
      attr_accessor :registered_address
      # The relationship that this person has with the account's legal entity.
      attr_accessor :relationship
      # The last four digits of the person's Social Security number (U.S. only).
      attr_accessor :ssn_last_4
      # Demographic data related to the person.
      attr_accessor :us_cfpb_data
      # The person's verification status.
      attr_accessor :verification

      def initialize(
        additional_tos_acceptances: nil,
        address: nil,
        address_kana: nil,
        address_kanji: nil,
        dob: nil,
        documents: nil,
        email: nil,
        first_name: nil,
        first_name_kana: nil,
        first_name_kanji: nil,
        full_name_aliases: nil,
        gender: nil,
        id_number: nil,
        id_number_secondary: nil,
        last_name: nil,
        last_name_kana: nil,
        last_name_kanji: nil,
        maiden_name: nil,
        metadata: nil,
        nationality: nil,
        phone: nil,
        political_exposure: nil,
        registered_address: nil,
        relationship: nil,
        ssn_last_4: nil,
        us_cfpb_data: nil,
        verification: nil
      )
        @additional_tos_acceptances = additional_tos_acceptances
        @address = address
        @address_kana = address_kana
        @address_kanji = address_kanji
        @dob = dob
        @documents = documents
        @email = email
        @first_name = first_name
        @first_name_kana = first_name_kana
        @first_name_kanji = first_name_kanji
        @full_name_aliases = full_name_aliases
        @gender = gender
        @id_number = id_number
        @id_number_secondary = id_number_secondary
        @last_name = last_name
        @last_name_kana = last_name_kana
        @last_name_kanji = last_name_kanji
        @maiden_name = maiden_name
        @metadata = metadata
        @nationality = nationality
        @phone = phone
        @political_exposure = political_exposure
        @registered_address = registered_address
        @relationship = relationship
        @ssn_last_4 = ssn_last_4
        @us_cfpb_data = us_cfpb_data
        @verification = verification
      end
    end

    class Pii < ::Stripe::RequestParams
      # The `id_number` for the PII, in string form.
      attr_accessor :id_number

      def initialize(id_number: nil)
        @id_number = id_number
      end
    end
    # Information for the account this token represents.
    attr_accessor :account
    # The bank account this token will represent.
    attr_accessor :bank_account
    # The card this token will represent. If you also pass in a customer, the card must be the ID of a card belonging to the customer. Otherwise, if you do not pass in a customer, this is a dictionary containing a user's credit card details, with the options described below.
    attr_accessor :card
    # Create a token for the customer, which is owned by the application's account. You can only use this with an [OAuth access token](https://stripe.com/docs/connect/standard-accounts) or [Stripe-Account header](https://stripe.com/docs/connect/authentication). Learn more about [cloning saved payment methods](https://stripe.com/docs/connect/cloning-saved-payment-methods).
    attr_accessor :customer
    # The updated CVC value this token represents.
    attr_accessor :cvc_update
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Information for the person this token represents.
    attr_accessor :person
    # The PII this token represents.
    attr_accessor :pii

    def initialize(
      account: nil,
      bank_account: nil,
      card: nil,
      customer: nil,
      cvc_update: nil,
      expand: nil,
      person: nil,
      pii: nil
    )
      @account = account
      @bank_account = bank_account
      @card = card
      @customer = customer
      @cvc_update = cvc_update
      @expand = expand
      @person = person
      @pii = pii
    end
  end
end
