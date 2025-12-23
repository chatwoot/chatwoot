# frozen_string_literal: true

module RuboCop
  module Cop
    # An offense represents a style violation detected by RuboCop.
    class Offense
      include Comparable

      # @api private
      COMPARISON_ATTRIBUTES = %i[line column cop_name message severity].freeze

      # @api public
      #
      # @!attribute [r] severity
      #
      # @return [RuboCop::Cop::Severity]
      attr_reader :severity

      # @api public
      #
      # @!attribute [r] location
      #
      # @return [Parser::Source::Range]
      #   the location where the violation is detected.
      #
      # @see https://www.rubydoc.info/gems/parser/Parser/Source/Range
      #   Parser::Source::Range
      attr_reader :location

      # @api public
      #
      # @!attribute [r] message
      #
      # @return [String]
      #   human-readable message
      #
      # @example
      #   'Line is too long. [90/80]'
      attr_reader :message

      # @api public
      #
      # @!attribute [r] cop_name
      #
      # @return [String]
      #   the cop name as a String for which this offense is for.
      #
      # @example
      #   'Layout/LineLength'
      attr_reader :cop_name

      # @api private
      attr_reader :status

      # @api public
      #
      # @!attribute [r] corrector
      #
      # @return [Corrector | nil]
      #   the autocorrection for this offense, or `nil` when not available
      attr_reader :corrector

      PseudoSourceRange = Struct.new(:line, :column, :source_line, :begin_pos,
                                     :end_pos) do
        alias_method :first_line, :line
        alias_method :last_line, :line
        alias_method :last_column, :column

        def column_range
          column...last_column
        end

        def size
          end_pos - begin_pos
        end
        alias_method :length, :size
      end
      private_constant :PseudoSourceRange

      NO_LOCATION = PseudoSourceRange.new(1, 0, '', 0, 0).freeze

      # @api private
      def initialize(severity, location, message, cop_name, # rubocop:disable Metrics/ParameterLists
                     status = :uncorrected, corrector = nil)
        @severity = RuboCop::Cop::Severity.new(severity)
        @location = location
        @message = message.freeze
        @cop_name = cop_name.freeze
        @status = status
        @corrector = corrector
        freeze
      end

      # @api public
      #
      # @!attribute [r] correctable?
      #
      # @return [Boolean]
      #   whether this offense can be automatically corrected via autocorrect.
      #   This includes todo comments, for example when requested with `--disable-uncorrectable`.
      def correctable?
        @status != :unsupported
      end

      # @api public
      #
      # @!attribute [r] corrected?
      #
      # @return [Boolean]
      #   whether this offense is automatically corrected via
      #   autocorrect or a todo.
      def corrected?
        @status == :corrected || @status == :corrected_with_todo
      end

      # @api public
      #
      # @!attribute [r] corrected_with_todo?
      #
      # @return [Boolean]
      #   whether this offense is automatically disabled via a todo.
      def corrected_with_todo?
        @status == :corrected_with_todo
      end

      # @api public
      #
      # @!attribute [r] disabled?
      #
      # @return [Boolean]
      #   whether this offense was locally disabled with a
      #   disable or todo where it occurred.
      def disabled?
        @status == :disabled || @status == :todo
      end

      # @api public
      #
      # @return [Parser::Source::Range]
      #   the range of the code that is highlighted
      def highlighted_area
        Parser::Source::Range.new(source_line, column, column + column_length)
      end

      # @api private
      # This is just for debugging purpose.
      def to_s
        format('%<severity>s:%3<line>d:%3<column>d: %<message>s',
               severity: severity.code, line: line,
               column: real_column, message: message)
      end

      # @api private
      def line
        location.line
      end

      # @api private
      def column
        location.column
      end

      # @api private
      def source_line
        location.source_line
      end

      # @api private
      def column_length
        if first_line == last_line
          column_range.count
        else
          source_line.length - column
        end
      end

      # @api private
      def first_line
        location.first_line
      end

      # @api private
      def last_line
        location.last_line
      end

      # @api private
      def last_column
        location.last_column
      end

      # @api private
      def column_range
        location.column_range
      end

      # @api private
      #
      # Internally we use column number that start at 0, but when
      # outputting column numbers, we want them to start at 1. One
      # reason is that editors, such as Emacs, expect this.
      def real_column
        column + 1
      end

      # @api public
      #
      # @return [Boolean]
      #   returns `true` if two offenses contain same attributes
      def ==(other)
        COMPARISON_ATTRIBUTES.all? do |attribute|
          public_send(attribute) == other.public_send(attribute)
        end
      end

      alias eql? ==

      def hash
        COMPARISON_ATTRIBUTES.map { |attribute| public_send(attribute) }.hash
      end

      # @api public
      #
      # Returns `-1`, `0`, or `+1`
      # if this offense is less than, equal to, or greater than `other`.
      #
      # @return [Integer]
      #   comparison result
      def <=>(other)
        COMPARISON_ATTRIBUTES.each do |attribute|
          result = public_send(attribute) <=> other.public_send(attribute)
          return result unless result.zero?
        end
        0
      end
    end
  end
end
