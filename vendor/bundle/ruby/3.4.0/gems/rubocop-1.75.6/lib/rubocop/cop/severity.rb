# frozen_string_literal: true

module RuboCop
  module Cop
    # Severity class is simple value object about severity
    class Severity
      include Comparable

      NAMES = %i[info refactor convention warning error fatal].freeze

      # @api private
      CODE_TABLE = { I: :info, R: :refactor, C: :convention,
                     W: :warning, E: :error, F: :fatal }.freeze

      # @api public
      #
      # @!attribute [r] name
      #
      # @return [Symbol]
      #   severity.
      #   any of `:info`, `:refactor`, `:convention`, `:warning`, `:error` or `:fatal`.
      attr_reader :name

      def self.name_from_code(code)
        name = code.to_sym
        CODE_TABLE[name] || name
      end

      # @api private
      def initialize(name_or_code)
        name = Severity.name_from_code(name_or_code)
        raise ArgumentError, "Unknown severity: #{name}" unless NAMES.include?(name)

        @name = name.freeze
        freeze
      end

      def to_s
        @name.to_s
      end

      def code
        @name.to_s[0].upcase
      end

      def level
        NAMES.index(name) + 1
      end

      def ==(other)
        @name == if other.is_a?(Symbol)
                   other
                 else
                   other.name
                 end
      end

      def hash
        @name.hash
      end

      def <=>(other)
        level <=> other.level
      end
    end
  end
end
