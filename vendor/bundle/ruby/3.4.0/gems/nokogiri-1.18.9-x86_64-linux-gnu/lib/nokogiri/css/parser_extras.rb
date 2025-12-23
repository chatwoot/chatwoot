# frozen_string_literal: true

require "thread"

module Nokogiri
  module CSS
    class Parser < Racc::Parser # :nodoc:
      def initialize
        @tokenizer = Tokenizer.new
        super
      end

      def parse(string)
        @tokenizer.scan_setup(string)
        do_parse
      end

      def next_token
        @tokenizer.next_token
      end

      # Get the xpath for +selector+ using +visitor+
      def xpath_for(selector, visitor)
        parse(selector).map do |ast|
          ast.to_xpath(visitor)
        end
      end

      # On CSS parser error, raise an exception
      def on_error(error_token_id, error_value, value_stack)
        after = value_stack.compact.last
        raise SyntaxError, "unexpected '#{error_value}' after '#{after}'"
      end
    end
  end
end
