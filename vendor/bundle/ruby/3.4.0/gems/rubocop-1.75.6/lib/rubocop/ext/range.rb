# frozen_string_literal: true

module RuboCop
  module Ext
    # Extensions to Parser::Source::Range
    module Range
      # Adds `Range#single_line?` to parallel `Node#single_line?`
      def single_line?
        first_line == last_line
      end
    end
  end
end

Parser::Source::Range.include RuboCop::Ext::Range
