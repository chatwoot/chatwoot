# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class AuthorizationFinalizeAmountParams < ::Stripe::RequestParams
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
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The final authorization amount that will be captured by the merchant. This amount is in the authorization currency and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
      attr_accessor :final_amount
      # Fleet-specific information for authorizations using Fleet cards.
      attr_accessor :fleet
      # Information about fuel that was purchased with this transaction.
      attr_accessor :fuel

      def initialize(expand: nil, final_amount: nil, fleet: nil, fuel: nil)
        @expand = expand
        @final_amount = final_amount
        @fleet = fleet
        @fuel = fuel
      end
    end
  end
end
