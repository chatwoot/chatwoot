# frozen_string_literal: true

module RuboCop
  module Ext
    # Extensions to `Parser::Source::Comment`.
    module Comment
      def source
        loc.expression.source
      end

      def source_range
        loc.expression
      end
    end
  end
end

Parser::Source::Comment.include RuboCop::Ext::Comment
