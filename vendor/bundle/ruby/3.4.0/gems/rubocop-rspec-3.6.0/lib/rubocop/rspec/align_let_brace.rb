# frozen_string_literal: true

module RuboCop
  module RSpec
    # Shared behavior for aligning braces for single line lets
    class AlignLetBrace
      include RuboCop::RSpec::Language
      include RuboCop::Cop::Util

      def initialize(root, token)
        @root  = root
        @token = token
      end

      def offending_tokens
        single_line_lets.reject do |let|
          target_column_for(let) == let_token(let).column
        end
      end

      def indent_for(node)
        ' ' * (target_column_for(node) - let_token(node).column)
      end

      private

      def let_token(node)
        node.loc.public_send(token)
      end

      def target_column_for(let)
        let_group_for(let).map { |member| let_token(member).column }.max
      end

      def let_group_for(let)
        adjacent_let_chunks.detect do |chunk|
          chunk.any? do |member|
            member == let && same_line?(member, let)
          end
        end
      end

      def adjacent_let_chunks
        last_line = nil

        single_line_lets.chunk do |node|
          line      = node.loc.line
          last_line = (line if last_line.nil? || last_line + 1 == line)
          last_line.nil?
        end.map(&:last)
      end

      def single_line_lets
        @single_line_lets ||=
          root.each_node(:block).select do |node|
            let?(node) && node.single_line?
          end
      end

      attr_reader :root, :token
    end
  end
end
