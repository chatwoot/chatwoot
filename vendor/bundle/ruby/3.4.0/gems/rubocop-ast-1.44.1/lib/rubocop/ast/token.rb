# frozen_string_literal: true

module RuboCop
  module AST
    # A basic wrapper around Parser's tokens.
    class Token
      LEFT_PAREN_TYPES = %i[tLPAREN tLPAREN2].freeze
      LEFT_CURLY_TYPES = %i[tLCURLY tLAMBEG].freeze

      attr_reader :pos, :type, :text

      def self.from_parser_token(parser_token)
        type, details = parser_token
        text, range = details
        new(range, type, text)
      end

      def initialize(pos, type, text)
        @pos = pos
        @type = type
        # Parser token "text" may be an Integer
        @text = text.to_s
      end

      def line
        @pos.line
      end

      def column
        @pos.column
      end

      def begin_pos
        @pos.begin_pos
      end

      def end_pos
        @pos.end_pos
      end

      def to_s
        "[[#{line}, #{column}], #{type}, #{text.inspect}]"
      end

      # Checks if there is whitespace after token
      def space_after?
        pos.source_buffer.source.match(/\G\s/, end_pos)
      end

      # Checks if there is whitespace before token
      def space_before?
        position = begin_pos.zero? ? begin_pos : begin_pos - 1
        pos.source_buffer.source.match(/\G\s/, position)
      end

      ## Type Predicates

      def comment?
        type == :tCOMMENT
      end

      def semicolon?
        type == :tSEMI
      end

      def left_array_bracket?
        type == :tLBRACK
      end

      def left_ref_bracket?
        type == :tLBRACK2
      end

      def left_bracket?
        %i[tLBRACK tLBRACK2].include?(type)
      end

      def right_bracket?
        type == :tRBRACK
      end

      def left_brace?
        type == :tLBRACE
      end

      def left_curly_brace?
        LEFT_CURLY_TYPES.include?(type)
      end

      def right_curly_brace?
        type == :tRCURLY
      end

      def left_parens?
        LEFT_PAREN_TYPES.include?(type)
      end

      def right_parens?
        type == :tRPAREN
      end

      def comma?
        type == :tCOMMA
      end

      def dot?
        type == :tDOT
      end

      def regexp_dots?
        %i[tDOT2 tDOT3].include?(type)
      end

      def rescue_modifier?
        type == :kRESCUE_MOD
      end

      def end?
        type == :kEND
      end

      def equal_sign?
        %i[tEQL tOP_ASGN].include?(type)
      end

      def new_line?
        type == :tNL
      end
    end
  end
end
