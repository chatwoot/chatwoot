# frozen_string_literal: true

module RuboCop
  module Ext
    # Extensions for `regexp_parser` gem
    module RegexpParser
      # Source map for RegexpParser nodes
      class Map < ::Parser::Source::Map
        attr_reader :body, :quantifier, :begin, :end

        def initialize(expression, body:, quantifier: nil, begin_l: nil, end_l: nil)
          @begin = begin_l
          @end = end_l
          @body = body
          @quantifier = quantifier
          super(expression)
        end
      end

      module Expression
        # Add `expression` and `loc` to all `regexp_parser` nodes
        module Base
          attr_accessor :origin

          # Shortcut to `loc.expression`
          def expression
            @expression ||= origin.adjust(begin_pos: ts, end_pos: ts + full_length)
          end

          # @returns a location map like `parser` does, with:
          #   - expression: complete expression
          #   - quantifier: for `+`, `{1,2}`, etc.
          #   - begin/end: for `[` and `]` (only CharacterSet for now)
          #
          # E.g.
          #     [a-z]{2,}
          #     ^^^^^^^^^ expression
          #          ^^^^ quantifier
          #     ^^^^^     body
          #     ^         begin
          #         ^     end
          #
          # Please open issue if you need other locations
          def loc
            @loc ||= Map.new(expression, **build_location)
          end

          private

          def build_location
            return { body: expression } unless (q = quantifier)

            body = expression.adjust(end_pos: -q.text.length)
            q.origin = origin
            q_loc = q.expression

            { body: body, quantifier: q_loc }
          end
        end

        # Provide `CharacterSet` with `begin` and `end` locations.
        module CharacterSet
          def build_location
            h = super
            body = h[:body]
            h.merge!(
              begin_l: body.with(end_pos: body.begin_pos + 1),
              end_l: body.with(begin_pos: body.end_pos - 1)
            )
          end
        end
      end
      ::Regexp::Expression::Base.include Expression::Base
      ::Regexp::Expression::Quantifier.include Expression::Base
      ::Regexp::Expression::CharacterSet.include Expression::CharacterSet
    end
  end
end
