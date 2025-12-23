# frozen_string_literal: true

module Faker
  class Tea < Base
    flexible :tea

    class << self
      ##
      # Produces a random variety or blend of tea.
      #
      # @param type [String, nil] the type of tea to query for (valid types: 'Black', 'Green', 'Oolong', 'White', and 'Herbal')
      # @return [String] a variety of tea
      #
      # @example
      #   Faker::Tea.variety
      #     #=> "Earl Grey"
      #
      # @example
      #   Faker::Tea.variety(type: 'Green')
      #     #=> "Jasmine"
      # @faker.version next
      def variety(type: nil)
        type ||= fetch('tea.type')
        fetch "tea.variety.#{type.downcase}"
      end

      ##
      # Produces a random type of tea.
      #
      # @return [String] a type of tea
      #
      # @example
      #   Faker::Tea.type
      #     #=> "Green"
      # @faker.version next
      def type
        fetch 'tea.type'
      end
    end
  end
end
