# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderSetReaderDisplayParams < ::Stripe::RequestParams
      class Cart < ::Stripe::RequestParams
        class LineItem < ::Stripe::RequestParams
          # The price of the item in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
          attr_accessor :amount
          # The description or name of the item.
          attr_accessor :description
          # The quantity of the line item being purchased.
          attr_accessor :quantity

          def initialize(amount: nil, description: nil, quantity: nil)
            @amount = amount
            @description = description
            @quantity = quantity
          end
        end
        # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_accessor :currency
        # Array of line items to display.
        attr_accessor :line_items
        # The amount of tax in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_accessor :tax
        # Total balance of cart due in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_accessor :total

        def initialize(currency: nil, line_items: nil, tax: nil, total: nil)
          @currency = currency
          @line_items = line_items
          @tax = tax
          @total = total
        end
      end
      # Cart details to display on the reader screen, including line items, amounts, and currency.
      attr_accessor :cart
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Type of information to display. Only `cart` is currently supported.
      attr_accessor :type

      def initialize(cart: nil, expand: nil, type: nil)
        @cart = cart
        @expand = expand
        @type = type
      end
    end
  end
end
