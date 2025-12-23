# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Use `RUBY` for heredoc delimiter of example Ruby code.
      #
      # Some editors may apply better syntax highlighting by using appropriate language names for
      # the delimiter.
      #
      # @example
      #  # bad
      #  expect_offense(<<~CODE)
      #    example_ruby_code
      #  CODE
      #
      #  # good
      #  expect_offense(<<~RUBY)
      #    example_ruby_code
      #  RUBY
      class ExampleHeredocDelimiter < Base
        extend AutoCorrector

        EXPECTED_HEREDOC_DELIMITER = 'RUBY'

        MSG = 'Use `RUBY` for heredoc delimiter of example Ruby code.'

        RESTRICT_ON_SEND = %i[
          expect_correction
          expect_no_corrections
          expect_no_offenses
          expect_offense
        ].freeze

        # @param node [RuboCop::AST::SendNode]
        # @return [void]
        def on_send(node)
          heredoc_node = heredoc_node_from(node)
          return unless heredoc_node
          return if expected_heredoc_delimiter?(heredoc_node)
          return if expected_heredoc_delimiter_in_body?(heredoc_node)

          add_offense(heredoc_node) do |corrector|
            autocorrect(corrector, heredoc_node)
          end
        end

        private

        # @param corrector [RuboCop::Cop::Corrector]
        # @param node [RuboCop::AST::StrNode]
        # @return [void]
        def autocorrect(corrector, node)
          [
            heredoc_opening_delimiter_range_from(node),
            heredoc_closing_delimiter_range_from(node)
          ].each do |range|
            corrector.replace(range, EXPECTED_HEREDOC_DELIMITER)
          end
        end

        # @param node [RuboCop::AST::StrNode]
        # @return [Boolean]
        def expected_heredoc_delimiter_in_body?(node)
          node.location.heredoc_body.source.lines.any? do |line|
            line.strip == EXPECTED_HEREDOC_DELIMITER
          end
        end

        # @param node [RuboCop::AST::StrNode]
        # @return [Boolean]
        def expected_heredoc_delimiter?(node)
          heredoc_delimiter_string_from(node) == EXPECTED_HEREDOC_DELIMITER
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [RuboCop::AST::StrNode, nil]
        def heredoc_node_from(node)
          return unless node.first_argument.respond_to?(:heredoc?)
          return unless node.first_argument.heredoc?

          node.first_argument
        end

        # @param node [RuboCop::AST::StrNode]
        # @return [String]
        def heredoc_delimiter_string_from(node)
          node.source[Heredoc::OPENING_DELIMITER, 2]
        end

        # @param node [RuboCop::AST::StrNode]
        # @return [Parser::Source::Range]
        def heredoc_opening_delimiter_range_from(node)
          match_data = node.source.match(Heredoc::OPENING_DELIMITER)
          node.source_range.begin.adjust(
            begin_pos: match_data.begin(2),
            end_pos: match_data.end(2)
          )
        end

        # @param node [RuboCop::AST::StrNode]
        # @return [Parser::Source::Range]
        def heredoc_closing_delimiter_range_from(node)
          node.location.heredoc_end.end.adjust(
            begin_pos: -heredoc_delimiter_string_from(node).length
          )
        end
      end
    end
  end
end
