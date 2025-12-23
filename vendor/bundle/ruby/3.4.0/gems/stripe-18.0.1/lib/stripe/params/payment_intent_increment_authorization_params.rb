# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentIntentIncrementAuthorizationParams < ::Stripe::RequestParams
    class AmountDetails < ::Stripe::RequestParams
      class LineItem < ::Stripe::RequestParams
        class PaymentMethodOptions < ::Stripe::RequestParams
          class Card < ::Stripe::RequestParams
            # Identifier that categorizes the items being purchased using a standardized commodity scheme such as (but not limited to) UNSPSC, NAICS, NAPCS, etc.
            attr_accessor :commodity_code

            def initialize(commodity_code: nil)
              @commodity_code = commodity_code
            end
          end

          class CardPresent < ::Stripe::RequestParams
            # Identifier that categorizes the items being purchased using a standardized commodity scheme such as (but not limited to) UNSPSC, NAICS, NAPCS, etc.
            attr_accessor :commodity_code

            def initialize(commodity_code: nil)
              @commodity_code = commodity_code
            end
          end

          class Klarna < ::Stripe::RequestParams
            # URL to an image for the product. Max length, 4096 characters.
            attr_accessor :image_url
            # URL to the product page. Max length, 4096 characters.
            attr_accessor :product_url
            # Unique reference for this line item to correlate it with your system’s internal records. The field is displayed in the Klarna Consumer App if passed.
            attr_accessor :reference
            # Reference for the subscription this line item is for.
            attr_accessor :subscription_reference

            def initialize(
              image_url: nil,
              product_url: nil,
              reference: nil,
              subscription_reference: nil
            )
              @image_url = image_url
              @product_url = product_url
              @reference = reference
              @subscription_reference = subscription_reference
            end
          end

          class Paypal < ::Stripe::RequestParams
            # Type of the line item.
            attr_accessor :category
            # Description of the line item.
            attr_accessor :description
            # The Stripe account ID of the connected account that sells the item.
            attr_accessor :sold_by

            def initialize(category: nil, description: nil, sold_by: nil)
              @category = category
              @description = description
              @sold_by = sold_by
            end
          end
          # This sub-hash contains line item details that are specific to `card` payment method."
          attr_accessor :card
          # This sub-hash contains line item details that are specific to `card_present` payment method."
          attr_accessor :card_present
          # This sub-hash contains line item details that are specific to `klarna` payment method."
          attr_accessor :klarna
          # This sub-hash contains line item details that are specific to `paypal` payment method."
          attr_accessor :paypal

          def initialize(card: nil, card_present: nil, klarna: nil, paypal: nil)
            @card = card
            @card_present = card_present
            @klarna = klarna
            @paypal = paypal
          end
        end

        class Tax < ::Stripe::RequestParams
          # The total amount of tax on a single line item represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). Required for L3 rates. An integer greater than or equal to 0.
          #
          # This field is mutually exclusive with the `amount_details[tax][total_tax_amount]` field.
          attr_accessor :total_tax_amount

          def initialize(total_tax_amount: nil)
            @total_tax_amount = total_tax_amount
          end
        end
        # The discount applied on this line item represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). An integer greater than 0.
        #
        # This field is mutually exclusive with the `amount_details[discount_amount]` field.
        attr_accessor :discount_amount
        # Payment method-specific information for line items.
        attr_accessor :payment_method_options
        # The product code of the line item, such as an SKU. Required for L3 rates. At most 12 characters long.
        attr_accessor :product_code
        # The product name of the line item. Required for L3 rates. At most 1024 characters long.
        #
        # For Cards, this field is truncated to 26 alphanumeric characters before being sent to the card networks. For Paypal, this field is truncated to 127 characters.
        attr_accessor :product_name
        # The quantity of items. Required for L3 rates. An integer greater than 0.
        attr_accessor :quantity
        # Contains information about the tax on the item.
        attr_accessor :tax
        # The unit cost of the line item represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). Required for L3 rates. An integer greater than or equal to 0.
        attr_accessor :unit_cost
        # A unit of measure for the line item, such as gallons, feet, meters, etc.
        attr_accessor :unit_of_measure

        def initialize(
          discount_amount: nil,
          payment_method_options: nil,
          product_code: nil,
          product_name: nil,
          quantity: nil,
          tax: nil,
          unit_cost: nil,
          unit_of_measure: nil
        )
          @discount_amount = discount_amount
          @payment_method_options = payment_method_options
          @product_code = product_code
          @product_name = product_name
          @quantity = quantity
          @tax = tax
          @unit_cost = unit_cost
          @unit_of_measure = unit_of_measure
        end
      end

      class Shipping < ::Stripe::RequestParams
        # If a physical good is being shipped, the cost of shipping represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). An integer greater than or equal to 0.
        attr_accessor :amount
        # If a physical good is being shipped, the postal code of where it is being shipped from. At most 10 alphanumeric characters long, hyphens are allowed.
        attr_accessor :from_postal_code
        # If a physical good is being shipped, the postal code of where it is being shipped to. At most 10 alphanumeric characters long, hyphens are allowed.
        attr_accessor :to_postal_code

        def initialize(amount: nil, from_postal_code: nil, to_postal_code: nil)
          @amount = amount
          @from_postal_code = from_postal_code
          @to_postal_code = to_postal_code
        end
      end

      class Tax < ::Stripe::RequestParams
        # The total amount of tax on the transaction represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). Required for L2 rates. An integer greater than or equal to 0.
        #
        # This field is mutually exclusive with the `amount_details[line_items][#][tax][total_tax_amount]` field.
        attr_accessor :total_tax_amount

        def initialize(total_tax_amount: nil)
          @total_tax_amount = total_tax_amount
        end
      end
      # The total discount applied on the transaction represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). An integer greater than 0.
      #
      # This field is mutually exclusive with the `amount_details[line_items][#][discount_amount]` field.
      attr_accessor :discount_amount
      # A list of line items, each containing information about a product in the PaymentIntent. There is a maximum of 100 line items.
      attr_accessor :line_items
      # Contains information about the shipping portion of the amount.
      attr_accessor :shipping
      # Contains information about the tax portion of the amount.
      attr_accessor :tax

      def initialize(discount_amount: nil, line_items: nil, shipping: nil, tax: nil)
        @discount_amount = discount_amount
        @line_items = line_items
        @shipping = shipping
        @tax = tax
      end
    end

    class Hooks < ::Stripe::RequestParams
      class Inputs < ::Stripe::RequestParams
        class Tax < ::Stripe::RequestParams
          # The [TaxCalculation](https://stripe.com/docs/api/tax/calculations) id
          attr_accessor :calculation

          def initialize(calculation: nil)
            @calculation = calculation
          end
        end
        # Tax arguments for automations
        attr_accessor :tax

        def initialize(tax: nil)
          @tax = tax
        end
      end
      # Arguments passed in automations
      attr_accessor :inputs

      def initialize(inputs: nil)
        @inputs = inputs
      end
    end

    class PaymentDetails < ::Stripe::RequestParams
      # A unique value to identify the customer. This field is available only for card payments.
      #
      # This field is truncated to 25 alphanumeric characters, excluding spaces, before being sent to card networks.
      attr_accessor :customer_reference
      # A unique value assigned by the business to identify the transaction. Required for L2 and L3 rates.
      #
      # Required when the Payment Method Types array contains `card`, including when [automatic_payment_methods.enabled](/api/payment_intents/create#create_payment_intent-automatic_payment_methods-enabled) is set to `true`.
      #
      # For Cards, this field is truncated to 25 alphanumeric characters, excluding spaces, before being sent to card networks. For Klarna, this field is truncated to 255 characters and is visible to customers when they view the order in the Klarna app.
      attr_accessor :order_reference

      def initialize(customer_reference: nil, order_reference: nil)
        @customer_reference = customer_reference
        @order_reference = order_reference
      end
    end

    class TransferData < ::Stripe::RequestParams
      # The amount that will be transferred automatically when a charge succeeds.
      attr_accessor :amount

      def initialize(amount: nil)
        @amount = amount
      end
    end
    # The updated total amount that you intend to collect from the cardholder. This amount must be greater than the currently authorized amount.
    attr_accessor :amount
    # Provides industry-specific information about the amount.
    attr_accessor :amount_details
    # The amount of the application fee (if any) that will be requested to be applied to the payment and transferred to the application owner's Stripe account. The amount of the application fee collected will be capped at the total amount captured. For more information, see the PaymentIntents [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts).
    attr_accessor :application_fee_amount
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_accessor :description
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Automations to be run during the PaymentIntent lifecycle
    attr_accessor :hooks
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Provides industry-specific information about the charge.
    attr_accessor :payment_details
    # Text that appears on the customer's statement as the statement descriptor for a non-card or card charge. This value overrides the account's default statement descriptor. For information about requirements, including the 22-character limit, see [the Statement Descriptor docs](https://docs.stripe.com/get-started/account/statement-descriptors).
    attr_accessor :statement_descriptor
    # The parameters used to automatically create a transfer after the payment is captured.
    # Learn more about the [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts).
    attr_accessor :transfer_data

    def initialize(
      amount: nil,
      amount_details: nil,
      application_fee_amount: nil,
      description: nil,
      expand: nil,
      hooks: nil,
      metadata: nil,
      payment_details: nil,
      statement_descriptor: nil,
      transfer_data: nil
    )
      @amount = amount
      @amount_details = amount_details
      @application_fee_amount = application_fee_amount
      @description = description
      @expand = expand
      @hooks = hooks
      @metadata = metadata
      @payment_details = payment_details
      @statement_descriptor = statement_descriptor
      @transfer_data = transfer_data
    end
  end
end
