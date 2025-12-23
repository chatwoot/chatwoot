# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Ensures that eval methods (`eval`, `instance_eval`, `class_eval`
      # and `module_eval`) are given filename and line number values (`+__FILE__+`
      # and `+__LINE__+`). This data is used to ensure that any errors raised
      # within the evaluated code will be given the correct identification
      # in a backtrace.
      #
      # The cop also checks that the line number given relative to `+__LINE__+` is
      # correct.
      #
      # This cop will autocorrect incorrect or missing filename and line number
      # values. However, if `eval` is called without a binding argument, the cop
      # will not attempt to automatically add a binding, or add filename and
      # line values.
      #
      # NOTE: This cop works only when a string literal is given as a code string.
      # No offense is reported if a string variable is given as below:
      #
      # [source,ruby]
      # ----
      # code = <<-RUBY
      #   def do_something
      #   end
      # RUBY
      # eval code # not checked.
      # ----
      #
      # @example
      #   # bad
      #   eval <<-RUBY
      #     def do_something
      #     end
      #   RUBY
      #
      #   # bad
      #   C.class_eval <<-RUBY
      #     def do_something
      #     end
      #   RUBY
      #
      #   # good
      #   eval <<-RUBY, binding, __FILE__, __LINE__ + 1
      #     def do_something
      #     end
      #   RUBY
      #
      #   # good
      #   C.class_eval <<-RUBY, __FILE__, __LINE__ + 1
      #     def do_something
      #     end
      #   RUBY
      #
      class EvalWithLocation < Base
        extend AutoCorrector

        MSG = 'Pass `__FILE__` and `__LINE__` to `%<method_name>s`.'
        MSG_EVAL = 'Pass a binding, `__FILE__`, and `__LINE__` to `eval`.'
        MSG_INCORRECT_FILE = 'Incorrect file for `%<method_name>s`; ' \
                             'use `%<expected>s` instead of `%<actual>s`.'
        MSG_INCORRECT_LINE = 'Incorrect line number for `%<method_name>s`; ' \
                             'use `%<expected>s` instead of `%<actual>s`.'

        RESTRICT_ON_SEND = %i[eval class_eval module_eval instance_eval].freeze

        # @!method valid_eval_receiver?(node)
        def_node_matcher :valid_eval_receiver?, <<~PATTERN
          { nil? (const {nil? cbase} :Kernel) }
        PATTERN

        # @!method line_with_offset?(node, sign, num)
        def_node_matcher :line_with_offset?, <<~PATTERN
          {
            (send #special_line_keyword? %1 (int %2))
            (send (int %2) %1 #special_line_keyword?)
          }
        PATTERN

        def on_send(node)
          # Classes should not redefine eval, but in case one does, it shouldn't
          # register an offense. Only `eval` without a receiver and `Kernel.eval`
          # are considered.
          return if node.method?(:eval) && !valid_eval_receiver?(node.receiver)

          code = node.first_argument
          return unless code&.type?(:str, :dstr)

          check_location(node, code)
        end

        private

        def check_location(node, code)
          file, line = file_and_line(node)

          if line
            check_file(node, file)
            check_line(node, code)
          elsif file
            check_file(node, file)
            add_offense_for_missing_line(node, code)
          else
            add_offense_for_missing_location(node, code)
          end
        end

        def register_offense(node, &block)
          msg = node.method?(:eval) ? MSG_EVAL : format(MSG, method_name: node.method_name)
          add_offense(node, message: msg, &block)
        end

        def special_file_keyword?(node)
          node.str_type? && node.source == '__FILE__'
        end

        def special_line_keyword?(node)
          node.int_type? && node.source == '__LINE__'
        end

        def file_and_line(node)
          base = node.method?(:eval) ? 2 : 1
          [node.arguments[base], node.arguments[base + 1]]
        end

        def with_binding?(node)
          node.method?(:eval) ? node.arguments.size >= 2 : true
        end

        def add_offense_for_incorrect_line(method_name, line_node, sign, line_diff)
          expected = expected_line(sign, line_diff)
          message = format(MSG_INCORRECT_LINE,
                           method_name: method_name,
                           actual: line_node.source,
                           expected: expected)

          add_offense(line_node, message: message) do |corrector|
            corrector.replace(line_node, expected)
          end
        end

        def check_file(node, file_node)
          return if special_file_keyword?(file_node)

          message = format(MSG_INCORRECT_FILE,
                           method_name: node.method_name,
                           expected: '__FILE__',
                           actual: file_node.source)

          add_offense(file_node, message: message) do |corrector|
            corrector.replace(file_node, '__FILE__')
          end
        end

        def check_line(node, code)
          line_node = node.last_argument
          return if line_node.variable? || (line_node.send_type? && !line_node.method?(:+))

          line_diff = line_difference(line_node, code)
          if line_diff.zero?
            add_offense_for_same_line(node, line_node)
          else
            add_offense_for_different_line(node, line_node, line_diff)
          end
        end

        def line_difference(line_node, code)
          string_first_line(code) - line_node.source_range.first_line
        end

        def string_first_line(str_node)
          if str_node.heredoc?
            str_node.loc.heredoc_body.first_line
          else
            str_node.source_range.first_line
          end
        end

        def add_offense_for_same_line(node, line_node)
          return if special_line_keyword?(line_node)

          add_offense_for_incorrect_line(node.method_name, line_node, nil, 0)
        end

        def add_offense_for_different_line(node, line_node, line_diff)
          sign = line_diff.positive? ? :+ : :-
          return if line_with_offset?(line_node, sign, line_diff.abs)

          add_offense_for_incorrect_line(node.method_name, line_node, sign, line_diff.abs)
        end

        def expected_line(sign, line_diff)
          if line_diff.zero?
            '__LINE__'
          else
            "__LINE__ #{sign} #{line_diff.abs}"
          end
        end

        def add_offense_for_missing_line(node, code)
          register_offense(node) do |corrector|
            line_str = missing_line(node, code)
            corrector.insert_after(node.last_argument.source_range.end, ", #{line_str}")
          end
        end

        def add_offense_for_missing_location(node, code)
          if node.method?(:eval) && !with_binding?(node)
            register_offense(node)
            return
          end

          register_offense(node) do |corrector|
            line_str = missing_line(node, code)
            corrector.insert_after(node.last_argument.source_range.end, ", __FILE__, #{line_str}")
          end
        end

        def missing_line(node, code)
          line_diff = line_difference(node.last_argument, code)
          sign = line_diff.positive? ? :+ : :-
          expected_line(sign, line_diff)
        end
      end
    end
  end
end
