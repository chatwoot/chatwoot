# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderPresentPaymentMethodParams < ::Stripe::RequestParams
      class Card < ::Stripe::RequestParams
        # Card security code.
        attr_accessor :cvc
        # Two-digit number representing the card's expiration month.
        attr_accessor :exp_month
        # Two- or four-digit number representing the card's expiration year.
        attr_accessor :exp_year
        # The card number, as a string without any separators.
        attr_accessor :number

        def initialize(cvc: nil, exp_month: nil, exp_year: nil, number: nil)
          @cvc = cvc
          @exp_month = exp_month
          @exp_year = exp_year
          @number = number
        end
      end

      class CardPresent < ::Stripe::RequestParams
        # The card number, as a string without any separators.
        attr_accessor :number

        def initialize(number: nil)
          @number = number
        end
      end

      class InteracPresent < ::Stripe::RequestParams
        # The Interac card number.
        attr_accessor :number

        def initialize(number: nil)
          @number = number
        end
      end
      # Simulated on-reader tip amount.
      attr_accessor :amount_tip
      # Simulated data for the card payment method.
      attr_accessor :card
      # Simulated data for the card_present payment method.
      attr_accessor :card_present
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Simulated data for the interac_present payment method.
      attr_accessor :interac_present
      # Simulated payment type.
      attr_accessor :type

      def initialize(
        amount_tip: nil,
        card: nil,
        card_present: nil,
        expand: nil,
        interac_present: nil,
        type: nil
      )
        @amount_tip = amount_tip
        @card = card
        @card_present = card_present
        @expand = expand
        @interac_present = interac_present
        @type = type
      end
    end
  end
end
