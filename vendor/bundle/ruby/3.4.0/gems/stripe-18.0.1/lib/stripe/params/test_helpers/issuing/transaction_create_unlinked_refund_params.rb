# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Issuing
      class TransactionCreateUnlinkedRefundParams < ::Stripe::RequestParams
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

        class PurchaseDetails < ::Stripe::RequestParams
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

          class Flight < ::Stripe::RequestParams
            class Segment < ::Stripe::RequestParams
              # The three-letter IATA airport code of the flight's destination.
              attr_accessor :arrival_airport_code
              # The airline carrier code.
              attr_accessor :carrier
              # The three-letter IATA airport code that the flight departed from.
              attr_accessor :departure_airport_code
              # The flight number.
              attr_accessor :flight_number
              # The flight's service class.
              attr_accessor :service_class
              # Whether a stopover is allowed on this flight.
              attr_accessor :stopover_allowed

              def initialize(
                arrival_airport_code: nil,
                carrier: nil,
                departure_airport_code: nil,
                flight_number: nil,
                service_class: nil,
                stopover_allowed: nil
              )
                @arrival_airport_code = arrival_airport_code
                @carrier = carrier
                @departure_airport_code = departure_airport_code
                @flight_number = flight_number
                @service_class = service_class
                @stopover_allowed = stopover_allowed
              end
            end
            # The time that the flight departed.
            attr_accessor :departure_at
            # The name of the passenger.
            attr_accessor :passenger_name
            # Whether the ticket is refundable.
            attr_accessor :refundable
            # The legs of the trip.
            attr_accessor :segments
            # The travel agency that issued the ticket.
            attr_accessor :travel_agency

            def initialize(
              departure_at: nil,
              passenger_name: nil,
              refundable: nil,
              segments: nil,
              travel_agency: nil
            )
              @departure_at = departure_at
              @passenger_name = passenger_name
              @refundable = refundable
              @segments = segments
              @travel_agency = travel_agency
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

          class Lodging < ::Stripe::RequestParams
            # The time of checking into the lodging.
            attr_accessor :check_in_at
            # The number of nights stayed at the lodging.
            attr_accessor :nights

            def initialize(check_in_at: nil, nights: nil)
              @check_in_at = check_in_at
              @nights = nights
            end
          end

          class Receipt < ::Stripe::RequestParams
            # Attribute for param field description
            attr_accessor :description
            # Attribute for param field quantity
            attr_accessor :quantity
            # Attribute for param field total
            attr_accessor :total
            # Attribute for param field unit_cost
            attr_accessor :unit_cost

            def initialize(description: nil, quantity: nil, total: nil, unit_cost: nil)
              @description = description
              @quantity = quantity
              @total = total
              @unit_cost = unit_cost
            end
          end
          # Fleet-specific information for transactions using Fleet cards.
          attr_accessor :fleet
          # Information about the flight that was purchased with this transaction.
          attr_accessor :flight
          # Information about fuel that was purchased with this transaction.
          attr_accessor :fuel
          # Information about lodging that was purchased with this transaction.
          attr_accessor :lodging
          # The line items in the purchase.
          attr_accessor :receipt
          # A merchant-specific order number.
          attr_accessor :reference

          def initialize(
            fleet: nil,
            flight: nil,
            fuel: nil,
            lodging: nil,
            receipt: nil,
            reference: nil
          )
            @fleet = fleet
            @flight = flight
            @fuel = fuel
            @lodging = lodging
            @receipt = receipt
            @reference = reference
          end
        end
        # The total amount to attempt to refund. This amount is in the provided currency, or defaults to the cards currency, and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_accessor :amount
        # Card associated with this unlinked refund transaction.
        attr_accessor :card
        # The currency of the unlinked refund. If not provided, defaults to the currency of the card. Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_accessor :currency
        # Specifies which fields in the response should be expanded.
        attr_accessor :expand
        # Details about the seller (grocery store, e-commerce website, etc.) where the card authorization happened.
        attr_accessor :merchant_data
        # Additional purchase information that is optionally provided by the merchant.
        attr_accessor :purchase_details

        def initialize(
          amount: nil,
          card: nil,
          currency: nil,
          expand: nil,
          merchant_data: nil,
          purchase_details: nil
        )
          @amount = amount
          @card = card
          @currency = currency
          @expand = expand
          @merchant_data = merchant_data
          @purchase_details = purchase_details
        end
      end
    end
  end
end
