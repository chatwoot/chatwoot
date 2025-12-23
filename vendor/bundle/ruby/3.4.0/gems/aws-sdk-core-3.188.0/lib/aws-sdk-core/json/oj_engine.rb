# frozen_string_literal: true

module Aws
  module Json
    module OjEngine
      # @api private
      LOAD_OPTIONS = { mode: :compat, symbol_keys: false, empty_string: false }.freeze

      # @api private
      DUMP_OPTIONS = { mode: :compat }.freeze

      class << self
        def load(json)
          Oj.load(json, LOAD_OPTIONS)
        rescue *PARSE_ERRORS => e
          raise ParseError.new(e)
        end

        def dump(value)
          Oj.dump(value, DUMP_OPTIONS)
        end

        private

        # Oj before 1.4.0 does not define Oj::ParseError and instead raises
        # SyntaxError on failure
        def detect_oj_parse_errors
          require 'oj'

          if Oj.const_defined?(:ParseError)
            [Oj::ParseError, EncodingError, JSON::ParserError]
          else
            [SyntaxError]
          end
        rescue LoadError
          nil
        end
      end

      # @api private
      PARSE_ERRORS = detect_oj_parse_errors
    end
  end
end
