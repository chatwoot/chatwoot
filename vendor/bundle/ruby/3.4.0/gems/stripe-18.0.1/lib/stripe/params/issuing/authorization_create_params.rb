# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class AuthorizationCreateParams < ::Stripe::RequestParams
      class AmountDetails < ::Stripe::RequestParams
        # The ATM withdrawal fee.
        attr_accessor :atm_fee
        # The amount of cash requested by the cardholder.
        attr_accessor :cashback_amount

        def initialize(atm_fee: nil, cashback_amount: nil)
          @atm_fee = atm_fee
          @cashback_amount = cashback_amount
        end
      end

      class Fleet < ::Stripe::RequestParams
        class CardholderPromptData < ::Stripe::RequestParams
          # Driver ID.
          attr_accessor :driver_id
          # Odometer reading.
          attr_accessor :odometer
          # An alphanumeric ID. This field is used when a vehicle ID, driver ID, or generic ID is entered by the cardholder, but the merchant or card network did not specify the prompt type.
          attr_accessor :unspecified_id
          # User ID.
          attr_accessor :user_id
          # Vehicle number.
          attr_accessor :vehicle_number

          def initialize(
            driver_id: nil,
            odometer: nil,
            unspecified_id: nil,
            user_id: nil,
            vehicle_number: nil
          )
            @driver_id = driver_id
            @odometer = odometer
            @unspecified_id = unspecified_id
            @user_id = user_id
            @vehicle_number = vehicle_number
          end
        end

        class ReportedBreakdown < ::Stripe::RequestParams
          class Fuel < ::Stripe::RequestParams
            # Gross fuel amount that should equal Fuel Volume multipled by Fuel Unit Cost, inclusive of taxes.
            attr_accessor :gross_amount_decimal

            def initialize(gross_amount_decimal: nil)
              @gross_amount_decimal = gross_amount_decimal
            end
          end

          class NonFuel < ::Stripe::RequestParams
            # Gross non-fuel amount that should equal the sum of the line items, inclusive of taxes.
            attr_accessor :gross_amount_decimal

            def initialize(gross_amount_decimal: nil)
              @gross_amount_decimal = gross_amount_decimal
            end
          end

          class Tax < ::Stripe::RequestParams
            # Amount of state or provincial Sales Tax included in the transaction amount. Null if not reported by merchant or not subject to tax.
            attr_accessor :local_amount_decimal
            # Amount of national Sales Tax or VAT included in the transaction amount. Null if not reported by merchant or not subject to tax.
            attr_accessor :national_amount_decimal

            def initialize(local_amount_decimal: nil, national_amount_decimal: nil)
              @local_amount_decimal = local_amount_decimal
              @national_amount_decimal = national_amount_decimal
            end
          end
          # Breakdown of fuel portion of the purchase.
          attr_accessor :fuel
          # Breakdown of non-fuel portion of the purchase.
          attr_accessor :non_fuel
          # Information about tax included in this transaction.
          attr_accessor :tax

          def initialize(fuel: nil, non_fuel: nil, tax: nil)
            @fuel = fuel
            @non_fuel = non_fuel
            @tax = tax
          end
        end
        # Answers to prompts presented to the cardholder at the point of sale. Prompted fields vary depending on the configuration of your physical fleet cards. Typical points of sale support only numeric entry.
        attr_accessor :cardholder_prompt_data
        # The type of purchase. One of `fuel_purchase`, `non_fuel_purchase`, or `fuel_and_non_fuel_purchase`.
        attr_accessor :purchase_type
        # More information about the total amount. This information is not guaranteed to be accurate as some merchants may provide unreliable data.
        attr_accessor :reported_breakdown
        # The type of fuel service. One of `non_fuel_transaction`, `full_service`, or `self_service`.
        attr_accessor :service_type

        def initialize(
          cardholder_prompt_data: nil,
          purchase_type: nil,
          reported_breakdown: nil,
          service_type: nil
        )
          @cardholder_prompt_data = cardholder_prompt_data
          @purchase_type = purchase_type
          @reported_breakdown = reported_breakdown
          @service_type = service_type
        end
      end

      class Fuel < ::Stripe::RequestParams
        # [Conexxus Payment System Product Code](https://www.conexxus.org/conexxus-payment-system-product-codes) identifying the primary fuel product purchased.
        attr_accessor :industry_product_code
        # The quantity of `unit`s of fuel that was dispensed, represented as a decimal string with at most 12 decimal places.
        attr_accessor :quantity_decimal
        # The type of fuel that was purchased. One of `diesel`, `unleaded_plus`, `unleaded_regular`, `unleaded_super`, or `other`.
        attr_accessor :type
        # The units for `quantity_decimal`. One of `charging_minute`, `imperial_gallon`, `kilogram`, `kilowatt_hour`, `liter`, `pound`, `us_gallon`, or `other`.
        attr_accessor :unit
        # The cost in cents per each unit of fuel, represented as a decimal string with at most 12 decimal places.
        attr_accessor :unit_cost_decimal

        def initialize(
          industry_product_code: nil,
          quantity_decimal: nil,
          type: nil,
          unit: nil,
          unit_cost_decimal: nil
        )
          @industry_product_code = industry_product_code
          @quantity_decimal = quantity_decimal
          @type = type
          @unit = unit
          @unit_cost_decimal = unit_cost_decimal
        end
      end

      class MerchantData < ::Stripe::RequestParams
        # A categorization of the seller's type of business. See our [merchant categories guide](https://stripe.com/docs/issuing/merchant-categories) for a list of possible values.
        attr_accessor :category
        # City where the seller is located
        attr_accessor :city
        # Country where the seller is located
        attr_accessor :country
        # Name of the seller
        attr_accessor :name
        # Identifier assigned to the seller by the card network. Different card networks may assign different network_id fields to the same merchant.
        attr_accessor :network_id
        # Postal code where the seller is located
        attr_accessor :postal_code
        # State where the seller is located
        attr_accessor :state
        # An ID assigned by the seller to the location of the sale.
        attr_accessor :terminal_id
        # URL provided by the merchant on a 3DS request
        attr_accessor :url

        def initialize(
          category: nil,
          city: nil,
          country: nil,
          name: nil,
          network_id: nil,
          postal_code: nil,
          state: nil,
          terminal_id: nil,
          url: nil
        )
          @category = category
          @city = city
          @country = country
          @name = name
          @network_id = network_id
          @postal_code = postal_code
          @state = state
          @terminal_id = terminal_id
          @url = url
        end
      end

      class NetworkData < ::Stripe::RequestParams
        # Identifier assigned to the acquirer by the card network.
        attr_accessor :acquiring_institution_id

        def initialize(acquiring_institution_id: nil)
          @acquiring_institution_id = acquiring_institution_id
        end
      end

      class RiskAssessment < ::Stripe::RequestParams
        class CardTestingRisk < ::Stripe::RequestParams
          # The % of declines due to a card number not existing in the past hour, taking place at the same merchant. Higher rates correspond to a greater probability of card testing activity, meaning bad actors may be attempting different card number combinations to guess a correct one. Takes on values between 0 and 100.
          attr_accessor :invalid_account_number_decline_rate_past_hour
          # The % of declines due to incorrect verification data (like CVV or expiry) in the past hour, taking place at the same merchant. Higher rates correspond to a greater probability of bad actors attempting to utilize valid card credentials at merchants with verification requirements. Takes on values between 0 and 100.
          attr_accessor :invalid_credentials_decline_rate_past_hour
          # The likelihood that this authorization is associated with card testing activity. This is assessed by evaluating decline activity over the last hour.
          attr_accessor :risk_level

          def initialize(
            invalid_account_number_decline_rate_past_hour: nil,
            invalid_credentials_decline_rate_past_hour: nil,
            risk_level: nil
          )
            @invalid_account_number_decline_rate_past_hour = invalid_account_number_decline_rate_past_hour
            @invalid_credentials_decline_rate_past_hour = invalid_credentials_decline_rate_past_hour
            @risk_level = risk_level
          end
        end

        class FraudRisk < ::Stripe::RequestParams
          # Stripe’s assessment of the likelihood of fraud on an authorization.
          attr_accessor :level
          # Stripe’s numerical model score assessing the likelihood of fraudulent activity. A higher score means a higher likelihood of fraudulent activity, and anything above 25 is considered high risk.
          attr_accessor :score

          def initialize(level: nil, score: nil)
            @level = level
            @score = score
          end
        end

        class MerchantDisputeRisk < ::Stripe::RequestParams
          # The dispute rate observed across all Stripe Issuing authorizations for this merchant. For example, a value of 50 means 50% of authorizations from this merchant on Stripe Issuing have resulted in a dispute. Higher values mean a higher likelihood the authorization is disputed. Takes on values between 0 and 100.
          attr_accessor :dispute_rate
          # The likelihood that authorizations from this merchant will result in a dispute based on their history on Stripe Issuing.
          attr_accessor :risk_level

          def initialize(dispute_rate: nil, risk_level: nil)
            @dispute_rate = dispute_rate
            @risk_level = risk_level
          end
        end
        # Stripe's assessment of this authorization's likelihood of being card testing activity.
        attr_accessor :card_testing_risk
        # Stripe’s assessment of this authorization’s likelihood to be fraudulent.
        attr_accessor :fraud_risk
        # The dispute risk of the merchant (the seller on a purchase) on an authorization based on all Stripe Issuing activity.
        attr_accessor :merchant_dispute_risk

        def initialize(card_testing_risk: nil, fraud_risk: nil, merchant_dispute_risk: nil)
          @card_testing_risk = card_testing_risk
          @fraud_risk = fraud_risk
          @merchant_dispute_risk = merchant_dispute_risk
        end
      end

      class VerificationData < ::Stripe::RequestParams
        class AuthenticationExemption < ::Stripe::RequestParams
          # The entity that requested the exemption, either the acquiring merchant or the Issuing user.
          attr_accessor :claimed_by
          # The specific exemption claimed for this authorization.
          attr_accessor :type

          def initialize(claimed_by: nil, type: nil)
            @claimed_by = claimed_by
            @type = type
          end
        end

        class ThreeDSecure < ::Stripe::RequestParams
          # The outcome of the 3D Secure authentication request.
          attr_accessor :result

          def initialize(result: nil)
            @result = result
          end
        end
        # Whether the cardholder provided an address first line and if it matched the cardholder’s `billing.address.line1`.
        attr_accessor :address_line1_check
        # Whether the cardholder provided a postal code and if it matched the cardholder’s `billing.address.postal_code`.
        attr_accessor :address_postal_code_check
        # The exemption applied to this authorization.
        attr_accessor :authentication_exemption
        # Whether the cardholder provided a CVC and if it matched Stripe’s record.
        attr_accessor :cvc_check
        # Whether the cardholder provided an expiry date and if it matched Stripe’s record.
        attr_accessor :expiry_check
        # 3D Secure details.
        attr_accessor :three_d_secure

        def initialize(
          address_line1_check: nil,
          address_postal_code_check: nil,
          authentication_exemption: nil,
          cvc_check: nil,
          expiry_check: nil,
          three_d_secure: nil
        )
          @address_line1_check = address_line1_check
          @address_postal_code_check = address_postal_code_check
          @authentication_exemption = authentication_exemption
          @cvc_check = cvc_check
          @expiry_check = expiry_check
          @three_d_secure = three_d_secure
        end
      end
      # The total amount to attempt to authorize. This amount is in the provided currency, or defaults to the card's currency, and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
      attr_accessor :amount
      # Detailed breakdown of amount components. These amounts are denominated in `currency` and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
      attr_accessor :amount_details
      # How the card details were provided. Defaults to online.
      attr_accessor :authorization_method
      # Card associated with this authorization.
      attr_accessor :card
      # The currency of the authorization. If not provided, defaults to the currency of the card. Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Fleet-specific information for authorizations using Fleet cards.
      attr_accessor :fleet
      # Probability that this transaction can be disputed in the event of fraud. Assessed by comparing the characteristics of the authorization to card network rules.
      attr_accessor :fraud_disputability_likelihood
      # Information about fuel that was purchased with this transaction.
      attr_accessor :fuel
      # If set `true`, you may provide [amount](https://stripe.com/docs/api/issuing/authorizations/approve#approve_issuing_authorization-amount) to control how much to hold for the authorization.
      attr_accessor :is_amount_controllable
      # The total amount to attempt to authorize. This amount is in the provided merchant currency, and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
      attr_accessor :merchant_amount
      # The currency of the authorization. If not provided, defaults to the currency of the card. Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :merchant_currency
      # Details about the seller (grocery store, e-commerce website, etc.) where the card authorization happened.
      attr_accessor :merchant_data
      # Details about the authorization, such as identifiers, set by the card network.
      attr_accessor :network_data
      # Stripe’s assessment of the fraud risk for this authorization.
      attr_accessor :risk_assessment
      # Verifications that Stripe performed on information that the cardholder provided to the merchant.
      attr_accessor :verification_data
      # The digital wallet used for this transaction. One of `apple_pay`, `google_pay`, or `samsung_pay`. Will populate as `null` when no digital wallet was utilized.
      attr_accessor :wallet

      def initialize(
        amount: nil,
        amount_details: nil,
        authorization_method: nil,
        card: nil,
        currency: nil,
        expand: nil,
        fleet: nil,
        fraud_disputability_likelihood: nil,
        fuel: nil,
        is_amount_controllable: nil,
        merchant_amount: nil,
        merchant_currency: nil,
        merchant_data: nil,
        network_data: nil,
        risk_assessment: nil,
        verification_data: nil,
        wallet: nil
      )
        @amount = amount
        @amount_details = amount_details
        @authorization_method = authorization_method
        @card = card
        @currency = currency
        @expand = expand
        @fleet = fleet
        @fraud_disputability_likelihood = fraud_disputability_likelihood
        @fuel = fuel
        @is_amount_controllable = is_amount_controllable
        @merchant_amount = merchant_amount
        @merchant_currency = merchant_currency
        @merchant_data = merchant_data
        @network_data = network_data
        @risk_assessment = risk_assessment
        @verification_data = verification_data
        @wallet = wallet
      end
    end
  end
end
