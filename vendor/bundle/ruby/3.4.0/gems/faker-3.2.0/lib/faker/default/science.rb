# frozen_string_literal: true

module Faker
  class Science < Base
    class << self
      BRANCHES = {
        empirical: %i[empirical_natural_basic empirical_natural_applied empirical_social_basic empirical_social_applied],
        formal: %i[formal_basic formal_applied],
        natural: %i[empirical_natural_basic empirical_natural_applied],
        social: %i[empirical_social_basic empirical_social_applied],
        basic: %i[empirical_natural_basic empirical_social_basic formal_basic],
        applied: %i[empirical_natural_applied empirical_social_applied formal_applied]
      }.freeze

      ##
      # Produces a name of a science
      # You can optionally filter by specifying one or more of the following:
      # `:empirical, :formal, :natural, :social, :basic, :applied`
      # @see https://en.wikipedia.org/wiki/Science#Branches_of_science
      # @see Faker::Educator.subject
      #
      # @param branches [Array<Symbol>]
      # @return [String]
      #
      # @example
      #   Faker::Science.science #=> "Space science"
      #   Faker::Science.science(:natural, :applied) #=> "Engineering"
      #   Faker::Science.science(:formal, :applied) #=> "Computer Science"
      #
      # @faker.version next
      def science(*branches)
        selected = BRANCHES.values.flatten.uniq
        branches.each do |branch|
          selected &= BRANCHES[branch] if BRANCHES.key? branch
        end

        raise ArgumentError, 'Filters do not match any sciences' if selected.empty?

        sciences = []
        selected.each do |branch|
          sciences += translate("faker.science.branch.#{branch}")
        end

        sample(sciences)
      end

      ##
      # Produces the name of a element.
      #
      # @return [String]
      #
      # @example
      #   Faker::Science.element #=> "Carbon"
      #
      # @faker.version 1.8.5
      def element
        fetch('science.element')
      end

      ##
      # Produces the symbol of an element.
      #
      # @return [String]
      #
      # @example
      #   Faker::Science.element_symbol #=> "Pb"
      #
      # @faker.version 1.9.0
      def element_symbol
        fetch('science.element_symbol')
      end

      ##
      # Produces the state of an element.
      #
      # @return [String]
      #
      # @example
      #   Faker::Science.element_state #=> "Liquid"
      #
      # @faker.version next
      def element_state
        fetch('science.element_state')
      end

      ##
      # Produces the subcategory of an element.
      #
      # @return [String]
      #
      # @example
      #   Faker::Science.element_subcategory #=> "Reactive nonmetal"
      #
      # @faker.version next
      def element_subcategory
        fetch('science.element_subcategory')
      end

      ##
      # Produces the name of a scientist.
      #
      # @return [String]
      #
      # @example
      #   Faker::Science.scientist #=> "Isaac Newton"
      #
      # @faker.version 1.8.5
      def scientist
        fetch('science.scientist')
      end

      ##
      # Produces a scientifically sounding word
      #
      # @return [String]
      #
      # @example
      #   Faker::Science.modifier #=> "Quantum"
      #   Faker::Science.modifier #=> "Superconductive"
      #
      # @faker.version next
      def modifier
        fetch('science.modifier')
      end

      ##
      # Produces the name of a scientific tool.
      # By default it uses a science word modifier to generate more diverse data, which can be disabled.
      #
      # @param simple [Boolean] Whether to generate simple realistic tool names, (no Q-word).
      # @return [String]
      #
      # @example
      #   Faker::Science.tool #=> "Superconductive Microcentrifuge"
      #   Faker::Science.tool #=> "Portable Cryostat"
      #   Faker::Science.tool #=> "Quantum Spectrophotometer"
      #   Faker::Science.tool(simple: true) #=> "Microcentrifuge"
      #
      # @faker.version next
      def tool(simple: false)
        tool = fetch('science.tool')
        return tool if simple

        # Makes sure the modifier are different
        loop do
          modifier = self.modifier
          break unless tool.start_with?(modifier)
        end

        "#{modifier} #{tool}"
      end
    end
  end
end
