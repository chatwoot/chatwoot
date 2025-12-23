# frozen_string_literal: true

module Faker
  class University < Base
    flexible :university

    class << self
      ##
      # Produces a random university name.
      #
      # @return [String]
      #
      # @example
      #   Faker::University.name #=> "Eastern Mississippi Academy"
      #
      # @faker.version 1.5.0
      def name
        parse('university.name')
      end

      ##
      # Produces a random university prefix.
      #
      # @return [String]
      #
      # @example
      #   Faker::University.prefix #=> "Western"
      #
      # @faker.version 1.5.0
      def prefix
        fetch('university.prefix')
      end

      ##
      # Produces a random university suffix.
      #
      # @return [String]
      #
      # @example
      #   Faker::University.suffix #=> "Academy"
      #
      # @faker.version 1.5.0
      def suffix
        fetch('university.suffix')
      end

      ##
      # Produces a random greek organization.
      #
      # @return [String]
      #
      # @example
      #   Faker::University.greek_organization #=> "BEX"
      #
      # @faker.version 1.5.0
      def greek_organization
        Array.new(3) { |_| sample(greek_alphabet) }.join
      end

      ##
      # Produces a greek alphabet.
      #
      # @return [Array]
      #
      # @example
      #   Faker::University.greek_alphabet #=> ["Α", "B", "Γ", "Δ", ...]
      #
      # @faker.version 1.5.0
      def greek_alphabet
        %w[Α B Γ Δ E Z H Θ I K Λ M N Ξ
           O Π P Σ T Y Φ X Ψ Ω]
      end
    end
  end
end
