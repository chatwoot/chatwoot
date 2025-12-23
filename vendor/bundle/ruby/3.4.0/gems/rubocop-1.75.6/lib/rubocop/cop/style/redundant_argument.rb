# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for a redundant argument passed to certain methods.
      #
      # NOTE: This cop is limited to methods with single parameter.
      #
      # Method names and their redundant arguments can be configured like this:
      #
      # [source,yaml]
      # ----
      # Methods:
      #   join: ''
      #   sum: 0
      #   split: ' '
      #   chomp: "\n"
      #   chomp!: "\n"
      #   foo: 2
      # ----
      #
      # @safety
      #   This cop is unsafe because of the following limitations:
      #
      #   1. This cop matches by method names only and hence cannot tell apart
      #      methods with same name in different classes.
      #   2. This cop may be unsafe if certain special global variables (e.g. `$;`, `$/`) are set.
      #      That depends on the nature of the target methods, of course. For example, the default
      #      argument to join is `$OUTPUT_FIELD_SEPARATOR` (or `$,`) rather than `''`, and if that
      #      global is changed, `''` is no longer a redundant argument.
      #
      # @example
      #   # bad
      #   array.join('')
      #   [1, 2, 3].join("")
      #   array.sum(0)
      #   exit(true)
      #   exit!(false)
      #   string.split(" ")
      #   "first\nsecond".split(" ")
      #   string.chomp("\n")
      #   string.chomp!("\n")
      #   A.foo(2)
      #
      #   # good
      #   array.join
      #   [1, 2, 3].join
      #   array.sum
      #   exit
      #   exit!
      #   string.split
      #   "first second".split
      #   string.chomp
      #   string.chomp!
      #   A.foo
      class RedundantArgument < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Argument %<arg>s is redundant because it is implied by default.'
        NO_RECEIVER_METHODS = %i[exit exit!].freeze

        def on_send(node)
          return if !NO_RECEIVER_METHODS.include?(node.method_name) && node.receiver.nil?
          return if node.arguments.count != 1
          return unless redundant_argument?(node)

          offense_range = argument_range(node)
          message = format(MSG, arg: node.first_argument.source)

          add_offense(offense_range, message: message) do |corrector|
            corrector.remove(offense_range)
          end
        end
        alias on_csend on_send

        private

        def redundant_argument?(node)
          redundant_argument = redundant_arg_for_method(node.method_name.to_s)
          return false if redundant_argument.nil?

          target_argument = if node.first_argument.respond_to?(:value)
                              node.first_argument.value
                            else
                              node.first_argument
                            end

          argument_matched?(target_argument, redundant_argument)
        end

        def redundant_arg_for_method(method_name)
          arg = cop_config['Methods'].fetch(method_name) { return }

          @mem ||= {}
          @mem[method_name] ||= arg.inspect
        end

        def argument_range(node)
          if node.parenthesized?
            range_between(node.loc.begin.begin_pos, node.loc.end.end_pos)
          else
            range_with_surrounding_space(node.first_argument.source_range, newlines: false)
          end
        end

        def argument_matched?(target_argument, redundant_argument)
          argument = if target_argument.is_a?(AST::Node)
                       target_argument.source
                     elsif exclude_cntrl_character?(target_argument, redundant_argument)
                       target_argument.inspect
                     else
                       target_argument.to_s
                     end

          argument == redundant_argument
        end

        def exclude_cntrl_character?(target_argument, redundant_argument)
          return true unless (target_argument_string = target_argument.to_s).valid_encoding?

          !target_argument_string.sub(/\A'/, '"').sub(/'\z/, '"').match?(/[[:cntrl:]]/) ||
            !redundant_argument.match?(/[[:cntrl:]]/)
        end
      end
    end
  end
end
