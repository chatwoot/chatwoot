# frozen_string_literal: true

module Faker
  class Stripe < Base
    class << self
      ##
      # Produces a random valid card number.
      #
      # @param card_type [String] Specific valid card type.
      # @return [String]
      #
      # @example
      #   Faker::Stripe.valid_card #=> "4242424242424242"
      #   Faker::Stripe.valid_card(card_type: "visa_debit") #=> "4000056655665556"
      #
      # @faker.version 1.9.0
      def valid_card(card_type: nil)
        valid_cards = translate('faker.stripe.valid_cards').keys

        if card_type.nil?
          card_type = sample(valid_cards).to_s
        else
          unless valid_cards.include?(card_type.to_sym)
            raise ArgumentError,
                  "Valid credit cards argument can be left blank or include #{valid_cards.join(', ')}"
          end
        end

        fetch("stripe.valid_cards.#{card_type}")
      end

      ##
      # Produces a random valid Stripe token.
      #
      # @param card_type [String] Specific valid card type.
      # @return [String]
      #
      # @example
      #   Faker::Stripe.valid_token #=> "tok_visa"
      #   Faker::Stripe.valid_token(card_type: "mc_debit") #=> "tok_mastercard_debit"
      #
      # @faker.version 1.9.0
      def valid_token(card_type: nil)
        valid_tokens = translate('faker.stripe.valid_tokens').keys

        if card_type.nil?
          card_type = sample(valid_tokens).to_s
        else
          unless valid_tokens.include?(card_type.to_sym)
            raise ArgumentError,
                  "Valid credit cards argument can be left blank or include #{valid_tokens.join(', ')}"
          end
        end

        fetch("stripe.valid_tokens.#{card_type}")
      end

      ##
      # Produces a random invalid card number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Stripe.invalid_card #=> "4000000000000002"
      #   Faker::Stripe.invalid_card(card_error: "addressZipFail") #=> "4000000000000010"
      #
      # @faker.version 1.9.0
      def invalid_card(card_error: nil)
        invalid_cards = translate('faker.stripe.invalid_cards').keys

        if card_error.nil?
          card_error = sample(invalid_cards).to_s
        else
          unless invalid_cards.include?(card_error.to_sym)
            raise ArgumentError,
                  "Invalid credit cards argument can be left blank or include #{invalid_cards.join(', ')}"
          end
        end

        fetch("stripe.invalid_cards.#{card_error}")
      end

      ##
      # Produces a random month in two digits format.
      #
      # @return [String]
      #
      # @example
      #   Faker::Stripe.month #=> "10"
      #
      # @faker.version 1.9.0
      def month
        format('%02d', rand_in_range(1, 12))
      end

      ##
      # Produces a random year that is always in the future.
      #
      # @return [String]
      #
      # @example
      #   Faker::Stripe.year #=> "2018" # This will always be a year in the future
      #
      # @faker.version 1.9.0
      def year
        start_year = ::Time.new.year + 1
        rand_in_range(start_year, start_year + 5).to_s
      end

      ##
      # Produces a random ccv number.
      #
      # @param card_type [String] Specific valid card type.
      # @return [String]
      #
      # @example
      #   Faker::Stripe.ccv #=> "123"
      #   Faker::Stripe.ccv(card_type: "amex") #=> "1234"
      #
      # @faker.version 1.9.0
      def ccv(card_type: nil)
        (card_type.to_s == 'amex' ? rand_in_range(1000, 9999) : rand_in_range(100, 999)).to_s
      end
    end
  end
end
