# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks if empty lines exist around the bodies of `begin`
      # sections. This cop doesn't check empty lines at `begin` body
      # beginning/end and around method definition body.
      # `Layout/EmptyLinesAroundBeginBody` or `Layout/EmptyLinesAroundMethodBody`
      # can be used for this purpose.
      #
      # @example
      #
      #   # good
      #
      #   begin
      #     do_something
      #   rescue
      #     do_something2
      #   else
      #     do_something3
      #   ensure
      #     do_something4
      #   end
      #
      #   # good
      #
      #   def foo
      #     do_something
      #   rescue
      #     do_something2
      #   end
      #
      #   # bad
      #
      #   begin
      #     do_something
      #
      #   rescue
      #
      #     do_something2
      #
      #   else
      #
      #     do_something3
      #
      #   ensure
      #
      #     do_something4
      #   end
      #
      #   # bad
      #
      #   def foo
      #     do_something
      #
      #   rescue
      #
      #     do_something2
      #   end
      class EmptyLinesAroundExceptionHandlingKeywords < Base
        include EmptyLinesAroundBody
        extend AutoCorrector

        MSG = 'Extra empty line detected %<location>s the `%<keyword>s`.'

        def on_def(node)
          check_body(node.body, node.loc.line)
        end
        alias on_defs on_def
        alias on_block on_def
        alias on_numblock on_def

        def on_kwbegin(node)
          check_body(node.children.first, node.loc.line)
        end

        private

        def check_body(body, line_of_def_or_kwbegin)
          locations = keyword_locations(body)

          locations.each do |loc|
            line = loc.line
            next if line == line_of_def_or_kwbegin || last_body_and_end_on_same_line?(body)

            keyword = loc.source
            # below the keyword
            check_line(style, line, message('after', keyword), &:empty?)
            # above the keyword
            check_line(style, line - 2, message('before', keyword), &:empty?)
          end
        end

        def last_body_and_end_on_same_line?(body)
          end_keyword_line = body.parent.loc.end.line
          return body.loc.last_line == end_keyword_line unless body.rescue_type?

          last_body_line = body.else? ? body.loc.else.line : body.resbody_branches.last.loc.line

          last_body_line == end_keyword_line
        end

        def message(location, keyword)
          format(MSG, location: location, keyword: keyword)
        end

        def style
          :no_empty_lines
        end

        def keyword_locations(node)
          return [] unless node

          case node.type
          when :rescue
            keyword_locations_in_rescue(node)
          when :ensure
            keyword_locations_in_ensure(node)
          else
            []
          end
        end

        def keyword_locations_in_rescue(node)
          [node.loc.else, *node.resbody_branches.map { |body| body.loc.keyword }].compact
        end

        def keyword_locations_in_ensure(node)
          rescue_body_without_ensure = node.children.first
          [
            node.loc.keyword,
            *keyword_locations(rescue_body_without_ensure)
          ]
        end
      end
    end
  end
end
