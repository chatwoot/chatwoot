# frozen_string_literal: true

module Faker
  class Commerce < Base
    class << self
      ##
      # Produces a random color.
      #
      # @return [String]
      #
      # @example
      #   Faker::Commerce.color #=> "lavender"
      #
      # @faker.version 1.2.0
      def color
        fetch('color.name')
      end

      ##
      # Produces a random promotion code.
      #
      # @param digits [Integer] Updates the number of numerical digits used to generate the promotion code.
      # @return [String]
      #
      # @example
      #   Faker::Commerce.promotion_code #=> "AmazingDeal829102"
      #   Faker::Commerce.promotion_code(digits: 2) #=> "AmazingPrice57"
      #
      # @faker.version 1.7.0
      def promotion_code(digits: 6)
        [
          fetch('commerce.promotion_code.adjective'),
          fetch('commerce.promotion_code.noun'),
          Faker::Number.number(digits: digits)
        ].join
      end

      ##
      # Produces a random department.
      #
      # @param max [Integer] Updates the maximum number of names used to generate the department name.
      # @param fixed_amount [Boolean] Fixes the amount of departments to use instead of using a range.
      # @return [String]
      #
      # @example
      #   Faker::Commerce.department #=> "Grocery, Health & Beauty"
      #   Faker::Commerce.department(max: 5) #=> "Grocery, Books, Health & Beauty"
      #   Faker::Commerce.department(max: 2, fixed_amount: true) #=> "Books & Tools"
      #
      # @faker.version 1.2.0
      def department(max: 3, fixed_amount: false)
        num = max if fixed_amount
        num ||= 1 + rand(max)

        categories = categories(num)

        if categories.is_a?(Array)
          if categories.length > 1
            merge_categories(categories)
          else
            categories[0]
          end
        else
          categories
        end
      end

      ##
      # Produces a random product name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Commerce.product_name #=> "Practical Granite Shirt"
      #
      # @faker.version 1.2.0
      def product_name
        "#{fetch('commerce.product_name.adjective')} #{fetch('commerce.product_name.material')} #{fetch('commerce.product_name.product')}"
      end

      ##
      # Produces a random material.
      #
      # @return [String]
      #
      # @example
      #   Faker::Commerce.material #=> "Plastic"
      #
      # @faker.version 1.5.0
      def material
        fetch('commerce.product_name.material')
      end

      ##
      # Produces a random product price.
      #
      # @param range [Range] A range to generate the random number within.
      # @param as_string [Boolean] Changes the return value to [String].
      # @return [Float]
      #
      # @example
      #   Faker::Commerce.price #=> 44.6
      #   Faker::Commerce.price(range: 0..10.0, as_string: true) #=> "2.18"
      #
      # @faker.version 1.2.0
      def price(range: 0..100.0, as_string: false)
        price = (rand(range) * 100).floor / 100.0
        if as_string
          price_parts = price.to_s.split('.')
          price = "#{price_parts[0]}.#{price_parts[-1].ljust(2, '0')}"
        end
        price
      end

      ##
      # Produces a randomized string of a brand name
      # @example
      #   Faker::Commerce.brand #=> 'Apple'
      #
      # @return [string]
      #
      # @faker.version next
      #
      ##
      def brand
        fetch('commerce.brand')
      end

      ##
      # Produces a randomized string of a vendor name
      # @example
      #   Faker::Commerce.vendor #=> 'Dollar General'
      #
      # @return [string]
      #
      # @faker.version next
      #
      ##
      def vendor
        fetch('commerce.vendor')
      end

      private

      def categories(num)
        sample(fetch_all('commerce.department'), num)
      end

      def merge_categories(categories)
        separator = fetch('separator')
        comma_separated = categories.slice!(0...-1).join(', ')

        [comma_separated, categories[0]].join(separator)
      end
    end
  end
end
