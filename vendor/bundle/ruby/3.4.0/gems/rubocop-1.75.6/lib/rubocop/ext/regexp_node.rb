# frozen_string_literal: true

module RuboCop
  module Ext
    # Extensions to AST::RegexpNode for our cached parsed regexp info
    module RegexpNode
      ANY = Object.new
      def ANY.==(_)
        true
      end
      private_constant :ANY

      # @return [Regexp::Expression::Root, nil]
      # Note: we extend Regexp nodes to provide `loc` and `expression`
      # see `ext/regexp_parser`.
      attr_reader :parsed_tree

      def assign_properties(*)
        super

        str = with_interpolations_blanked
        @parsed_tree = begin
          Regexp::Parser.parse(str, options: options)
        rescue StandardError
          nil
        end
        origin = loc.begin.end
        @parsed_tree&.each_expression(true) { |e| e.origin = origin }
      end

      def each_capture(named: ANY)
        return enum_for(__method__, named: named) unless block_given?

        parsed_tree&.traverse do |event, exp, _index|
          yield(exp) if named_capturing?(exp, event, named)
        end

        self
      end

      private

      def named_capturing?(exp, event, named)
        event == :enter &&
          named == exp.respond_to?(:name) &&
          exp.respond_to?(:capturing?) &&
          exp.capturing?
      end

      def with_interpolations_blanked
        # Ignore the trailing regopt node
        children[0...-1].map do |child|
          source = child.source

          # We don't want to consider the contents of interpolations as part of the pattern source,
          # but need to preserve their width, to allow offsets to correctly line up with the
          # original source: spaces have no effect, and preserve width.
          if child.begin_type?
            ' ' * source.length
          else
            source
          end
        end.join
      end

      AST::RegexpNode.include self
    end
  end
end
