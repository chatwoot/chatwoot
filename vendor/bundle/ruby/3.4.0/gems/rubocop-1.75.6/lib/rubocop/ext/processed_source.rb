# frozen_string_literal: true

module RuboCop
  module Ext
    # Extensions to AST::ProcessedSource for our cached comment_config
    module ProcessedSource
      attr_accessor :registry, :config

      def comment_config
        @comment_config ||= CommentConfig.new(self)
      end

      def disabled_line_ranges
        comment_config.cop_disabled_line_ranges
      end
    end
  end
end

RuboCop::ProcessedSource.include RuboCop::Ext::ProcessedSource
