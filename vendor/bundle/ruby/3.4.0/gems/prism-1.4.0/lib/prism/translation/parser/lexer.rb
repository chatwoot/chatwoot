# frozen_string_literal: true

require "strscan"
require_relative "../../polyfill/append_as_bytes"

module Prism
  module Translation
    class Parser
      # Accepts a list of prism tokens and converts them into the expected
      # format for the parser gem.
      class Lexer
        # These tokens are always skipped
        TYPES_ALWAYS_SKIP = Set.new(%i[IGNORED_NEWLINE __END__ EOF])
        private_constant :TYPES_ALWAYS_SKIP

        # The direct translating of types between the two lexers.
        TYPES = {
          # These tokens should never appear in the output of the lexer.
          MISSING: nil,
          NOT_PROVIDED: nil,
          EMBDOC_END: nil,
          EMBDOC_LINE: nil,

          # These tokens have more or less direct mappings.
          AMPERSAND: :tAMPER2,
          AMPERSAND_AMPERSAND: :tANDOP,
          AMPERSAND_AMPERSAND_EQUAL: :tOP_ASGN,
          AMPERSAND_DOT: :tANDDOT,
          AMPERSAND_EQUAL: :tOP_ASGN,
          BACK_REFERENCE: :tBACK_REF,
          BACKTICK: :tXSTRING_BEG,
          BANG: :tBANG,
          BANG_EQUAL: :tNEQ,
          BANG_TILDE: :tNMATCH,
          BRACE_LEFT: :tLCURLY,
          BRACE_RIGHT: :tRCURLY,
          BRACKET_LEFT: :tLBRACK2,
          BRACKET_LEFT_ARRAY: :tLBRACK,
          BRACKET_LEFT_RIGHT: :tAREF,
          BRACKET_LEFT_RIGHT_EQUAL: :tASET,
          BRACKET_RIGHT: :tRBRACK,
          CARET: :tCARET,
          CARET_EQUAL: :tOP_ASGN,
          CHARACTER_LITERAL: :tCHARACTER,
          CLASS_VARIABLE: :tCVAR,
          COLON: :tCOLON,
          COLON_COLON: :tCOLON2,
          COMMA: :tCOMMA,
          COMMENT: :tCOMMENT,
          CONSTANT: :tCONSTANT,
          DOT: :tDOT,
          DOT_DOT: :tDOT2,
          DOT_DOT_DOT: :tDOT3,
          EMBDOC_BEGIN: :tCOMMENT,
          EMBEXPR_BEGIN: :tSTRING_DBEG,
          EMBEXPR_END: :tSTRING_DEND,
          EMBVAR: :tSTRING_DVAR,
          EQUAL: :tEQL,
          EQUAL_EQUAL: :tEQ,
          EQUAL_EQUAL_EQUAL: :tEQQ,
          EQUAL_GREATER: :tASSOC,
          EQUAL_TILDE: :tMATCH,
          FLOAT: :tFLOAT,
          FLOAT_IMAGINARY: :tIMAGINARY,
          FLOAT_RATIONAL: :tRATIONAL,
          FLOAT_RATIONAL_IMAGINARY: :tIMAGINARY,
          GLOBAL_VARIABLE: :tGVAR,
          GREATER: :tGT,
          GREATER_EQUAL: :tGEQ,
          GREATER_GREATER: :tRSHFT,
          GREATER_GREATER_EQUAL: :tOP_ASGN,
          HEREDOC_START: :tSTRING_BEG,
          HEREDOC_END: :tSTRING_END,
          IDENTIFIER: :tIDENTIFIER,
          INSTANCE_VARIABLE: :tIVAR,
          INTEGER: :tINTEGER,
          INTEGER_IMAGINARY: :tIMAGINARY,
          INTEGER_RATIONAL: :tRATIONAL,
          INTEGER_RATIONAL_IMAGINARY: :tIMAGINARY,
          KEYWORD_ALIAS: :kALIAS,
          KEYWORD_AND: :kAND,
          KEYWORD_BEGIN: :kBEGIN,
          KEYWORD_BEGIN_UPCASE: :klBEGIN,
          KEYWORD_BREAK: :kBREAK,
          KEYWORD_CASE: :kCASE,
          KEYWORD_CLASS: :kCLASS,
          KEYWORD_DEF: :kDEF,
          KEYWORD_DEFINED: :kDEFINED,
          KEYWORD_DO: :kDO,
          KEYWORD_DO_LOOP: :kDO_COND,
          KEYWORD_END: :kEND,
          KEYWORD_END_UPCASE: :klEND,
          KEYWORD_ENSURE: :kENSURE,
          KEYWORD_ELSE: :kELSE,
          KEYWORD_ELSIF: :kELSIF,
          KEYWORD_FALSE: :kFALSE,
          KEYWORD_FOR: :kFOR,
          KEYWORD_IF: :kIF,
          KEYWORD_IF_MODIFIER: :kIF_MOD,
          KEYWORD_IN: :kIN,
          KEYWORD_MODULE: :kMODULE,
          KEYWORD_NEXT: :kNEXT,
          KEYWORD_NIL: :kNIL,
          KEYWORD_NOT: :kNOT,
          KEYWORD_OR: :kOR,
          KEYWORD_REDO: :kREDO,
          KEYWORD_RESCUE: :kRESCUE,
          KEYWORD_RESCUE_MODIFIER: :kRESCUE_MOD,
          KEYWORD_RETRY: :kRETRY,
          KEYWORD_RETURN: :kRETURN,
          KEYWORD_SELF: :kSELF,
          KEYWORD_SUPER: :kSUPER,
          KEYWORD_THEN: :kTHEN,
          KEYWORD_TRUE: :kTRUE,
          KEYWORD_UNDEF: :kUNDEF,
          KEYWORD_UNLESS: :kUNLESS,
          KEYWORD_UNLESS_MODIFIER: :kUNLESS_MOD,
          KEYWORD_UNTIL: :kUNTIL,
          KEYWORD_UNTIL_MODIFIER: :kUNTIL_MOD,
          KEYWORD_WHEN: :kWHEN,
          KEYWORD_WHILE: :kWHILE,
          KEYWORD_WHILE_MODIFIER: :kWHILE_MOD,
          KEYWORD_YIELD: :kYIELD,
          KEYWORD___ENCODING__: :k__ENCODING__,
          KEYWORD___FILE__: :k__FILE__,
          KEYWORD___LINE__: :k__LINE__,
          LABEL: :tLABEL,
          LABEL_END: :tLABEL_END,
          LAMBDA_BEGIN: :tLAMBEG,
          LESS: :tLT,
          LESS_EQUAL: :tLEQ,
          LESS_EQUAL_GREATER: :tCMP,
          LESS_LESS: :tLSHFT,
          LESS_LESS_EQUAL: :tOP_ASGN,
          METHOD_NAME: :tFID,
          MINUS: :tMINUS,
          MINUS_EQUAL: :tOP_ASGN,
          MINUS_GREATER: :tLAMBDA,
          NEWLINE: :tNL,
          NUMBERED_REFERENCE: :tNTH_REF,
          PARENTHESIS_LEFT: :tLPAREN2,
          PARENTHESIS_LEFT_PARENTHESES: :tLPAREN_ARG,
          PARENTHESIS_RIGHT: :tRPAREN,
          PERCENT: :tPERCENT,
          PERCENT_EQUAL: :tOP_ASGN,
          PERCENT_LOWER_I: :tQSYMBOLS_BEG,
          PERCENT_LOWER_W: :tQWORDS_BEG,
          PERCENT_UPPER_I: :tSYMBOLS_BEG,
          PERCENT_UPPER_W: :tWORDS_BEG,
          PERCENT_LOWER_X: :tXSTRING_BEG,
          PLUS: :tPLUS,
          PLUS_EQUAL: :tOP_ASGN,
          PIPE_EQUAL: :tOP_ASGN,
          PIPE: :tPIPE,
          PIPE_PIPE: :tOROP,
          PIPE_PIPE_EQUAL: :tOP_ASGN,
          QUESTION_MARK: :tEH,
          REGEXP_BEGIN: :tREGEXP_BEG,
          REGEXP_END: :tSTRING_END,
          SEMICOLON: :tSEMI,
          SLASH: :tDIVIDE,
          SLASH_EQUAL: :tOP_ASGN,
          STAR: :tSTAR2,
          STAR_EQUAL: :tOP_ASGN,
          STAR_STAR: :tPOW,
          STAR_STAR_EQUAL: :tOP_ASGN,
          STRING_BEGIN: :tSTRING_BEG,
          STRING_CONTENT: :tSTRING_CONTENT,
          STRING_END: :tSTRING_END,
          SYMBOL_BEGIN: :tSYMBEG,
          TILDE: :tTILDE,
          UAMPERSAND: :tAMPER,
          UCOLON_COLON: :tCOLON3,
          UDOT_DOT: :tBDOT2,
          UDOT_DOT_DOT: :tBDOT3,
          UMINUS: :tUMINUS,
          UMINUS_NUM: :tUNARY_NUM,
          UPLUS: :tUPLUS,
          USTAR: :tSTAR,
          USTAR_STAR: :tDSTAR,
          WORDS_SEP: :tSPACE
        }

        # These constants represent flags in our lex state. We really, really
        # don't want to be using them and we really, really don't want to be
        # exposing them as part of our public API. Unfortunately, we don't have
        # another way of matching the exact tokens that the parser gem expects
        # without them. We should find another way to do this, but in the
        # meantime we'll hide them from the documentation and mark them as
        # private constants.
        EXPR_BEG = 0x1 # :nodoc:
        EXPR_LABEL = 0x400 # :nodoc:

        # It is used to determine whether `do` is of the token type `kDO` or `kDO_LAMBDA`.
        #
        # NOTE: In edge cases like `-> (foo = -> (bar) {}) do end`, please note that `kDO` is still returned
        # instead of `kDO_LAMBDA`, which is expected: https://github.com/ruby/prism/pull/3046
        LAMBDA_TOKEN_TYPES = Set.new([:kDO_LAMBDA, :tLAMBDA, :tLAMBEG])

        # The `PARENTHESIS_LEFT` token in Prism is classified as either `tLPAREN` or `tLPAREN2` in the Parser gem.
        # The following token types are listed as those classified as `tLPAREN`.
        LPAREN_CONVERSION_TOKEN_TYPES = Set.new([
          :kBREAK, :kCASE, :tDIVIDE, :kFOR, :kIF, :kNEXT, :kRETURN, :kUNTIL, :kWHILE, :tAMPER, :tANDOP, :tBANG, :tCOMMA, :tDOT2, :tDOT3,
          :tEQL, :tLPAREN, :tLPAREN2, :tLPAREN_ARG, :tLSHFT, :tNL, :tOP_ASGN, :tOROP, :tPIPE, :tSEMI, :tSTRING_DBEG, :tUMINUS, :tUPLUS
        ])

        # Types of tokens that are allowed to continue a method call with comments in-between.
        # For these, the parser gem doesn't emit a newline token after the last comment.
        COMMENT_CONTINUATION_TYPES = Set.new([:COMMENT, :AMPERSAND_DOT, :DOT])
        private_constant :COMMENT_CONTINUATION_TYPES

        # Heredocs are complex and require us to keep track of a bit of info to refer to later
        HeredocData = Struct.new(:identifier, :common_whitespace, keyword_init: true)

        private_constant :TYPES, :EXPR_BEG, :EXPR_LABEL, :LAMBDA_TOKEN_TYPES, :LPAREN_CONVERSION_TOKEN_TYPES, :HeredocData

        # The Parser::Source::Buffer that the tokens were lexed from.
        attr_reader :source_buffer

        # An array of tuples that contain prism tokens and their associated lex
        # state when they were lexed.
        attr_reader :lexed

        # A hash that maps offsets in bytes to offsets in characters.
        attr_reader :offset_cache

        # Initialize the lexer with the given source buffer, prism tokens, and
        # offset cache.
        def initialize(source_buffer, lexed, offset_cache)
          @source_buffer = source_buffer
          @lexed = lexed
          @offset_cache = offset_cache
        end

        Range = ::Parser::Source::Range # :nodoc:
        private_constant :Range

        # Convert the prism tokens into the expected format for the parser gem.
        def to_a
          tokens = []

          index = 0
          length = lexed.length

          heredoc_stack = []
          quote_stack = []

          # The parser gem emits the newline tokens for comments out of order. This saves
          # that token location to emit at a later time to properly line everything up.
          # https://github.com/whitequark/parser/issues/1025
          comment_newline_location = nil

          while index < length
            token, state = lexed[index]
            index += 1
            next if TYPES_ALWAYS_SKIP.include?(token.type)

            type = TYPES.fetch(token.type)
            value = token.value
            location = range(token.location.start_offset, token.location.end_offset)

            case type
            when :kDO
              nearest_lambda_token = tokens.reverse_each.find do |token|
                LAMBDA_TOKEN_TYPES.include?(token.first)
              end

              if nearest_lambda_token&.first == :tLAMBDA
                type = :kDO_LAMBDA
              end
            when :tCHARACTER
              value.delete_prefix!("?")
              # Character literals behave similar to double-quoted strings. We can use the same escaping mechanism.
              value = unescape_string(value, "?")
            when :tCOMMENT
              if token.type == :EMBDOC_BEGIN

                while !((next_token = lexed[index][0]) && next_token.type == :EMBDOC_END) && (index < length - 1)
                  value += next_token.value
                  index += 1
                end

                value += next_token.value
                location = range(token.location.start_offset, lexed[index][0].location.end_offset)
                index += 1
              else
                is_at_eol = value.chomp!.nil?
                location = range(token.location.start_offset, token.location.end_offset + (is_at_eol ? 0 : -1))

                prev_token = lexed[index - 2][0] if index - 2 >= 0
                next_token = lexed[index][0]

                is_inline_comment = prev_token&.location&.start_line == token.location.start_line
                if is_inline_comment && !is_at_eol && !COMMENT_CONTINUATION_TYPES.include?(next_token&.type)
                  tokens << [:tCOMMENT, [value, location]]

                  nl_location = range(token.location.end_offset - 1, token.location.end_offset)
                  tokens << [:tNL, [nil, nl_location]]
                  next
                elsif is_inline_comment && next_token&.type == :COMMENT
                  comment_newline_location = range(token.location.end_offset - 1, token.location.end_offset)
                elsif comment_newline_location && !COMMENT_CONTINUATION_TYPES.include?(next_token&.type)
                  tokens << [:tCOMMENT, [value, location]]
                  tokens << [:tNL, [nil, comment_newline_location]]
                  comment_newline_location = nil
                  next
                end
              end
            when :tNL
              next_token = next_token = lexed[index][0]
              # Newlines after comments are emitted out of order.
              if next_token&.type == :COMMENT
                comment_newline_location = location
                next
              end

              value = nil
            when :tFLOAT
              value = parse_float(value)
            when :tIMAGINARY
              value = parse_complex(value)
            when :tINTEGER
              if value.start_with?("+")
                tokens << [:tUNARY_NUM, ["+", range(token.location.start_offset, token.location.start_offset + 1)]]
                location = range(token.location.start_offset + 1, token.location.end_offset)
              end

              value = parse_integer(value)
            when :tLABEL
              value.chomp!(":")
            when :tLABEL_END
              value.chomp!(":")
            when :tLCURLY
              type = :tLBRACE if state == EXPR_BEG | EXPR_LABEL
            when :tLPAREN2
              type = :tLPAREN if tokens.empty? || LPAREN_CONVERSION_TOKEN_TYPES.include?(tokens.dig(-1, 0))
            when :tNTH_REF
              value = parse_integer(value.delete_prefix("$"))
            when :tOP_ASGN
              value.chomp!("=")
            when :tRATIONAL
              value = parse_rational(value)
            when :tSPACE
              location = range(token.location.start_offset, token.location.start_offset + percent_array_leading_whitespace(value))
              value = nil
            when :tSTRING_BEG
              next_token = lexed[index][0]
              next_next_token = lexed[index + 1][0]
              basic_quotes = value == '"' || value == "'"

              if basic_quotes && next_token&.type == :STRING_END
                next_location = token.location.join(next_token.location)
                type = :tSTRING
                value = ""
                location = range(next_location.start_offset, next_location.end_offset)
                index += 1
              elsif value.start_with?("'", '"', "%")
                if next_token&.type == :STRING_CONTENT && next_next_token&.type == :STRING_END
                  string_value = next_token.value
                  if simplify_string?(string_value, value)
                    next_location = token.location.join(next_next_token.location)
                    if percent_array?(value)
                      value = percent_array_unescape(string_value)
                    else
                      value = unescape_string(string_value, value)
                    end
                    type = :tSTRING
                    location = range(next_location.start_offset, next_location.end_offset)
                    index += 2
                    tokens << [type, [value, location]]

                    next
                  end
                end

                quote_stack.push(value)
              elsif token.type == :HEREDOC_START
                quote = value[2] == "-" || value[2] == "~" ? value[3] : value[2]
                heredoc_type = value[2] == "-" || value[2] == "~" ? value[2] : ""
                heredoc = HeredocData.new(
                  identifier: value.match(/<<[-~]?["'`]?(?<heredoc_identifier>.*?)["'`]?\z/)[:heredoc_identifier],
                  common_whitespace: 0,
                )

                if quote == "`"
                  type = :tXSTRING_BEG
                end

                # The parser gem trims whitespace from squiggly heredocs. We must record
                # the most common whitespace to later remove.
                if heredoc_type == "~" || heredoc_type == "`"
                  heredoc.common_whitespace = calculate_heredoc_whitespace(index)
                end

                if quote == "'" || quote == '"' || quote == "`"
                  value = "<<#{quote}"
                else
                  value = '<<"'
                end

                heredoc_stack.push(heredoc)
                quote_stack.push(value)
              end
            when :tSTRING_CONTENT
              is_percent_array = percent_array?(quote_stack.last)

              if (lines = token.value.lines).one?
                # Prism usually emits a single token for strings with line continuations.
                # For squiggly heredocs they are not joined so we do that manually here.
                current_string = +""
                current_length = 0
                start_offset = token.location.start_offset
                while token.type == :STRING_CONTENT
                  current_length += token.value.bytesize
                  # Heredoc interpolation can have multiple STRING_CONTENT nodes on the same line.
                  is_first_token_on_line = lexed[index - 1] && token.location.start_line != lexed[index - 2][0].location&.start_line
                  # The parser gem only removes indentation when the heredoc is not nested
                  not_nested = heredoc_stack.size == 1
                  if is_percent_array
                    value = percent_array_unescape(token.value)
                  elsif is_first_token_on_line && not_nested && (current_heredoc = heredoc_stack.last).common_whitespace > 0
                    value = trim_heredoc_whitespace(token.value, current_heredoc)
                  end

                  current_string << unescape_string(value, quote_stack.last)
                  if (backslash_count = token.value[/(\\{1,})\n/, 1]&.length).nil? || backslash_count.even? || !interpolation?(quote_stack.last)
                    tokens << [:tSTRING_CONTENT, [current_string, range(start_offset, start_offset + current_length)]]
                    break
                  end
                  token = lexed[index][0]
                  index += 1
                end
              else
                # When the parser gem encounters a line continuation inside of a multiline string,
                # it emits a single string node. The backslash (and remaining newline) is removed.
                current_line = +""
                adjustment = 0
                start_offset = token.location.start_offset
                emit = false

                lines.each.with_index do |line, index|
                  chomped_line = line.chomp
                  backslash_count = chomped_line[/\\{1,}\z/]&.length || 0
                  is_interpolation = interpolation?(quote_stack.last)

                  if backslash_count.odd? && (is_interpolation || is_percent_array)
                    if is_percent_array
                      current_line << percent_array_unescape(line)
                      adjustment += 1
                    else
                      chomped_line.delete_suffix!("\\")
                      current_line << chomped_line
                      adjustment += 2
                    end
                    # If the string ends with a line continuation emit the remainder
                    emit = index == lines.count - 1
                  else
                    current_line << line
                    emit = true
                  end

                  if emit
                    end_offset = start_offset + current_line.bytesize + adjustment
                    tokens << [:tSTRING_CONTENT, [unescape_string(current_line, quote_stack.last), range(start_offset, end_offset)]]
                    start_offset = end_offset
                    current_line = +""
                    adjustment = 0
                  end
                end
              end
              next
            when :tSTRING_DVAR
              value = nil
            when :tSTRING_END
              if token.type == :HEREDOC_END && value.end_with?("\n")
                newline_length = value.end_with?("\r\n") ? 2 : 1
                value = heredoc_stack.pop.identifier
                location = range(token.location.start_offset, token.location.end_offset - newline_length)
              elsif token.type == :REGEXP_END
                value = value[0]
                location = range(token.location.start_offset, token.location.start_offset + 1)
              end

              if percent_array?(quote_stack.pop)
                prev_token = lexed[index - 2][0] if index - 2 >= 0
                empty = %i[PERCENT_LOWER_I PERCENT_LOWER_W PERCENT_UPPER_I PERCENT_UPPER_W].include?(prev_token&.type)
                ends_with_whitespace = prev_token&.type == :WORDS_SEP
                # parser always emits a space token after content in a percent array, even if no actual whitespace is present.
                if !empty && !ends_with_whitespace
                  tokens << [:tSPACE, [nil, range(token.location.start_offset, token.location.start_offset)]]
                end
              end
            when :tSYMBEG
              if (next_token = lexed[index][0]) && next_token.type != :STRING_CONTENT && next_token.type != :EMBEXPR_BEGIN && next_token.type != :EMBVAR && next_token.type != :STRING_END
                next_location = token.location.join(next_token.location)
                type = :tSYMBOL
                value = next_token.value
                value = { "~@" => "~", "!@" => "!" }.fetch(value, value)
                location = range(next_location.start_offset, next_location.end_offset)
                index += 1
              else
                quote_stack.push(value)
              end
            when :tFID
              if !tokens.empty? && tokens.dig(-1, 0) == :kDEF
                type = :tIDENTIFIER
              end
            when :tXSTRING_BEG
              if (next_token = lexed[index][0]) && !%i[STRING_CONTENT STRING_END EMBEXPR_BEGIN].include?(next_token.type)
                # self.`()
                type = :tBACK_REF2
              end
              quote_stack.push(value)
            when :tSYMBOLS_BEG, :tQSYMBOLS_BEG, :tWORDS_BEG, :tQWORDS_BEG
              if (next_token = lexed[index][0]) && next_token.type == :WORDS_SEP
                index += 1
              end

              quote_stack.push(value)
            when :tREGEXP_BEG
              quote_stack.push(value)
            end

            tokens << [type, [value, location]]

            if token.type == :REGEXP_END
              tokens << [:tREGEXP_OPT, [token.value[1..], range(token.location.start_offset + 1, token.location.end_offset)]]
            end
          end

          tokens
        end

        private

        # Creates a new parser range, taking prisms byte offsets into account
        def range(start_offset, end_offset)
          Range.new(source_buffer, offset_cache[start_offset], offset_cache[end_offset])
        end

        # Parse an integer from the string representation.
        def parse_integer(value)
          Integer(value)
        rescue ArgumentError
          0
        end

        # Parse a float from the string representation.
        def parse_float(value)
          Float(value)
        rescue ArgumentError
          0.0
        end

        # Parse a complex from the string representation.
        def parse_complex(value)
          value.chomp!("i")

          if value.end_with?("r")
            Complex(0, parse_rational(value))
          elsif value.start_with?(/0[BbOoDdXx]/)
            Complex(0, parse_integer(value))
          else
            Complex(0, value)
          end
        rescue ArgumentError
          0i
        end

        # Parse a rational from the string representation.
        def parse_rational(value)
          value.chomp!("r")

          if value.start_with?(/0[BbOoDdXx]/)
            Rational(parse_integer(value))
          else
            Rational(value)
          end
        rescue ArgumentError
          0r
        end

        # Wonky heredoc tab/spaces rules.
        # https://github.com/ruby/prism/blob/v1.3.0/src/prism.c#L10548-L10558
        def calculate_heredoc_whitespace(heredoc_token_index)
          next_token_index = heredoc_token_index
          nesting_level = 0
          previous_line = -1
          result = Float::MAX

          while (lexed[next_token_index] && next_token = lexed[next_token_index][0])
            next_token_index += 1
            next_next_token = lexed[next_token_index] && lexed[next_token_index][0]
            first_token_on_line = next_token.location.start_column == 0

            # String content inside nested heredocs and interpolation is ignored
            if next_token.type == :HEREDOC_START || next_token.type == :EMBEXPR_BEGIN
              # When interpolation is the first token of a line there is no string
              # content to check against. There will be no common whitespace.
              if nesting_level == 0 && first_token_on_line
                result = 0
              end
              nesting_level += 1
            elsif next_token.type == :HEREDOC_END || next_token.type == :EMBEXPR_END
              nesting_level -= 1
              # When we encountered the matching heredoc end, we can exit
              break if nesting_level == -1
            elsif next_token.type == :STRING_CONTENT && nesting_level == 0 && first_token_on_line
              common_whitespace = 0
              next_token.value[/^\s*/].each_char do |char|
                if char == "\t"
                  common_whitespace = (common_whitespace / 8 + 1) * 8;
                else
                  common_whitespace += 1
                end
              end

              is_first_token_on_line = next_token.location.start_line != previous_line
              # Whitespace is significant if followed by interpolation
              whitespace_only = common_whitespace == next_token.value.length && next_next_token&.location&.start_line != next_token.location.start_line
              if is_first_token_on_line && !whitespace_only && common_whitespace < result
                result = common_whitespace
                previous_line = next_token.location.start_line
              end
            end
          end
          result
        end

        # Wonky heredoc tab/spaces rules.
        # https://github.com/ruby/prism/blob/v1.3.0/src/prism.c#L16528-L16545
        def trim_heredoc_whitespace(string, heredoc)
          trimmed_whitespace = 0
          trimmed_characters = 0
          while (string[trimmed_characters] == "\t" || string[trimmed_characters] == " ") && trimmed_whitespace < heredoc.common_whitespace
            if string[trimmed_characters] == "\t"
              trimmed_whitespace = (trimmed_whitespace / 8 + 1) * 8;
              break if trimmed_whitespace > heredoc.common_whitespace
            else
              trimmed_whitespace += 1
            end
            trimmed_characters += 1
          end

          string[trimmed_characters..]
        end

        # Escape sequences that have special and should appear unescaped in the resulting string.
        ESCAPES = {
          "a" => "\a", "b" => "\b", "e" => "\e", "f" => "\f",
          "n" => "\n", "r" => "\r", "s" => "\s", "t" => "\t",
          "v" => "\v", "\\" => "\\"
        }.freeze
        private_constant :ESCAPES

        # When one of these delimiters is encountered, then the other
        # one is allowed to be escaped as well.
        DELIMITER_SYMETRY = { "[" => "]", "(" => ")", "{" => "}", "<" => ">" }.freeze
        private_constant :DELIMITER_SYMETRY


        # https://github.com/whitequark/parser/blob/v3.3.6.0/lib/parser/lexer-strings.rl#L14
        REGEXP_META_CHARACTERS = ["\\", "$", "(", ")", "*", "+", ".", "<", ">", "?", "[", "]", "^", "{", "|", "}"]
        private_constant :REGEXP_META_CHARACTERS

        # Apply Ruby string escaping rules
        def unescape_string(string, quote)
          # In single-quoted heredocs, everything is taken literally.
          return string if quote == "<<'"

          # OPTIMIZATION: Assume that few strings need escaping to speed up the common case.
          return string unless string.include?("\\")

          # Enclosing character for the string. `"` for `"foo"`, `{` for `%w{foo}`, etc.
          delimiter = quote[-1]

          if regexp?(quote)
            # Should be escaped handled to single-quoted heredocs. The only character that is
            # allowed to be escaped is the delimiter, except when that also has special meaning
            # in the regexp. Since all the symetry delimiters have special meaning, they don't need
            # to be considered separately.
            if REGEXP_META_CHARACTERS.include?(delimiter)
              string
            else
              # There can never be an even amount of backslashes. It would be a syntax error.
              string.gsub(/\\(#{Regexp.escape(delimiter)})/, '\1')
            end
          elsif interpolation?(quote)
            # Appending individual escape sequences may force the string out of its intended
            # encoding. Start out with binary and force it back later.
            result = "".b

            scanner = StringScanner.new(string)
            while (skipped = scanner.skip_until(/\\/))
              # Append what was just skipped over, excluding the found backslash.
              result.append_as_bytes(string.byteslice(scanner.pos - skipped, skipped - 1))
              escape_read(result, scanner, false, false)
            end

            # Add remaining chars
            result.append_as_bytes(string.byteslice(scanner.pos..))
            result.force_encoding(source_buffer.source.encoding)
          else
            delimiters = Regexp.escape("#{delimiter}#{DELIMITER_SYMETRY[delimiter]}")
            string.gsub(/\\([\\#{delimiters}])/, '\1')
          end
        end

        # Certain strings are merged into a single string token.
        def simplify_string?(value, quote)
          case quote
          when "'"
            # Only simplify 'foo'
            !value.include?("\n")
          when '"'
            # Simplify when every line ends with a line continuation, or it is the last line
            value.lines.all? do |line|
              !line.end_with?("\n") || line[/(\\*)$/, 1]&.length&.odd?
            end
          else
            # %q and similar are never simplified
            false
          end
        end

        # Escape a byte value, given the control and meta flags.
        def escape_build(value, control, meta)
          value &= 0x9f if control
          value |= 0x80 if meta
          value
        end

        # Read an escape out of the string scanner, given the control and meta
        # flags, and push the unescaped value into the result.
        def escape_read(result, scanner, control, meta)
          if scanner.skip("\n")
            # Line continuation
          elsif (value = ESCAPES[scanner.peek(1)])
            # Simple single-character escape sequences like \n
            result.append_as_bytes(value)
            scanner.pos += 1
          elsif (value = scanner.scan(/[0-7]{1,3}/))
            # \nnn
            result.append_as_bytes(escape_build(value.to_i(8), control, meta))
          elsif (value = scanner.scan(/x[0-9a-fA-F]{1,2}/))
            # \xnn
            result.append_as_bytes(escape_build(value[1..].to_i(16), control, meta))
          elsif (value = scanner.scan(/u[0-9a-fA-F]{4}/))
            # \unnnn
            result.append_as_bytes(value[1..].hex.chr(Encoding::UTF_8))
          elsif scanner.skip("u{}")
            # https://github.com/whitequark/parser/issues/856
          elsif (value = scanner.scan(/u{.*?}/))
            # \u{nnnn ...}
            value[2..-2].split.each do |unicode|
              result.append_as_bytes(unicode.hex.chr(Encoding::UTF_8))
            end
          elsif (value = scanner.scan(/c\\?(?=[[:print:]])|C-\\?(?=[[:print:]])/))
            # \cx or \C-x where x is an ASCII printable character
            escape_read(result, scanner, true, meta)
          elsif (value = scanner.scan(/M-\\?(?=[[:print:]])/))
            # \M-x where x is an ASCII printable character
            escape_read(result, scanner, control, true)
          elsif (byte = scanner.get_byte)
            # Something else after an escape.
            if control && byte == "?"
              result.append_as_bytes(escape_build(0x7f, false, meta))
            else
              result.append_as_bytes(escape_build(byte.ord, control, meta))
            end
          end
        end

        # In a percent array, certain whitespace can be preceeded with a backslash,
        # causing the following characters to be part of the previous element.
        def percent_array_unescape(string)
          string.gsub(/(\\)+[ \f\n\r\t\v]/) do |full_match|
            full_match.delete_prefix!("\\") if Regexp.last_match[1].length.odd?
            full_match
          end
        end

        # For %-arrays whitespace, the parser gem only considers whitespace before the newline.
        def percent_array_leading_whitespace(string)
          return 1 if string.start_with?("\n")

          leading_whitespace = 0
          string.each_char do |c|
            break if c == "\n"
            leading_whitespace += 1
          end
          leading_whitespace
        end

        # Determine if characters preceeded by a backslash should be escaped or not
        def interpolation?(quote)
          !quote.end_with?("'") && !quote.start_with?("%q", "%w", "%i", "%s")
        end

        # Regexp allow interpolation but are handled differently during unescaping
        def regexp?(quote)
          quote == "/" || quote.start_with?("%r")
        end

        # Determine if the string is part of a %-style array.
        def percent_array?(quote)
          quote.start_with?("%w", "%W", "%i", "%I")
        end
      end
    end
  end
end
