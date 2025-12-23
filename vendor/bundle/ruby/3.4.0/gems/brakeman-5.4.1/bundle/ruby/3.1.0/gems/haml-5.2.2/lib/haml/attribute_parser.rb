# frozen_string_literal: true

begin
  require 'ripper'
rescue LoadError
end
require 'temple/static_analyzer'

module Haml
  # Haml::AttriubuteParser parses Hash literal to { String (key name) => String (value literal) }.
  module AttributeParser
    class UnexpectedTokenError < StandardError; end
    class UnexpectedKeyError < StandardError; end

    # Indices in Ripper tokens
    TYPE = 1
    TEXT = 2

    IGNORED_TYPES = %i[on_sp on_ignored_nl].freeze

    class << self
      # @return [Boolean] - return true if AttributeParser.parse can be used.
      def available?
        defined?(Ripper) && Temple::StaticAnalyzer.available?
      end

      # @param  [String] exp - Old attributes literal or Hash literal generated from new attributes.
      # @return [Hash<String, String>,nil] - Return parsed attribute Hash whose values are Ruby literals, or return nil if argument is not a single Hash literal.
      def parse(exp)
        return nil unless hash_literal?(exp)

        hash = {}
        each_attribute(exp) do |key, value|
          hash[key] = value
        end
        hash
      rescue UnexpectedTokenError, UnexpectedKeyError
        nil
      end

      private

      # @param  [String] exp - Ruby expression
      # @return [Boolean] - Return true if exp is a single Hash literal
      def hash_literal?(exp)
        return false if Temple::StaticAnalyzer.syntax_error?(exp)
        sym, body = Ripper.sexp(exp)
        sym == :program && body.is_a?(Array) && body.size == 1 && body[0] && body[0][0] == :hash
      end

      # @param [Array] tokens - Ripper tokens. Scanned tokens will be destructively removed from this argument.
      # @return [String] - attribute name in String
      def shift_key!(tokens)
        while !tokens.empty? && IGNORED_TYPES.include?(tokens.first[TYPE])
          tokens.shift # ignore spaces
        end

        _, type, first_text = tokens.shift
        case type
        when :on_label # `key:`
          first_text.tr(':', '')
        when :on_symbeg # `:key =>`, `:'key' =>` or `:"key" =>`
          key = tokens.shift[TEXT]
          if first_text != ':' # `:'key'` or `:"key"`
            expect_string_end!(tokens.shift)
          end
          shift_hash_rocket!(tokens)
          key
        when :on_tstring_beg # `"key":`, `'key':` or `"key" =>`
          key = tokens.shift[TEXT]
          next_token = tokens.shift
          if next_token[TYPE] != :on_label_end # on_label_end is `":` or `':`, so `"key" =>`
            expect_string_end!(next_token)
            shift_hash_rocket!(tokens)
          end
          key
        else
          raise UnexpectedKeyError.new("unexpected token is given!: #{first_text} (#{type})")
        end
      end

      # @param [Array] token - Ripper token
      def expect_string_end!(token)
        if token[TYPE] != :on_tstring_end
          raise UnexpectedTokenError
        end
      end

      # @param [Array] tokens - Ripper tokens
      def shift_hash_rocket!(tokens)
        until tokens.empty?
          _, type, str = tokens.shift
          break if type == :on_op && str == '=>'
        end
      end

      # @param [String] hash_literal
      # @param [Proc] block - that takes [String, String] as arguments
      def each_attribute(hash_literal, &block)
        all_tokens = Ripper.lex(hash_literal.strip)
        all_tokens = all_tokens[1...-1] || [] # strip tokens for brackets

        each_balanced_tokens(all_tokens) do |tokens|
          key   = shift_key!(tokens)
          value = tokens.map {|t| t[2] }.join.strip
          block.call(key, value)
        end
      end

      # @param [Array] tokens - Ripper tokens
      # @param [Proc] block - that takes balanced Ripper tokens as arguments
      def each_balanced_tokens(tokens, &block)
        attr_tokens = []
        open_tokens = Hash.new { |h, k| h[k] = 0 }

        tokens.each do |token|
          case token[TYPE]
          when :on_comma
            if open_tokens.values.all?(&:zero?)
              block.call(attr_tokens)
              attr_tokens = []
              next
            end
          when :on_lbracket
            open_tokens[:array] += 1
          when :on_rbracket
            open_tokens[:array] -= 1
          when :on_lbrace
            open_tokens[:block] += 1
          when :on_rbrace
            open_tokens[:block] -= 1
          when :on_lparen
            open_tokens[:paren] += 1
          when :on_rparen
            open_tokens[:paren] -= 1
          when :on_embexpr_beg
            open_tokens[:embexpr] += 1
          when :on_embexpr_end
            open_tokens[:embexpr] -= 1
          when *IGNORED_TYPES
            next if attr_tokens.empty?
          end

          attr_tokens << token
        end
        block.call(attr_tokens) unless attr_tokens.empty?
      end
    end
  end
end
