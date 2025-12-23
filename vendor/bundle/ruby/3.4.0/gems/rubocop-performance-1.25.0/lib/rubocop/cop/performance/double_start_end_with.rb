# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Checks for double `#start_with?` or `#end_with?` calls
      # separated by `||`. In some cases such calls can be replaced
      # with an single `#start_with?`/`#end_with?` call.
      #
      # `IncludeActiveSupportAliases` configuration option is used to check for
      # `starts_with?` and `ends_with?`. These methods are defined by Active Support.
      #
      # @example
      #   # bad
      #   str.start_with?("a") || str.start_with?(Some::CONST)
      #   str.start_with?("a", "b") || str.start_with?("c")
      #   str.end_with?(var1) || str.end_with?(var2)
      #
      #   # good
      #   str.start_with?("a", Some::CONST)
      #   str.start_with?("a", "b", "c")
      #   str.end_with?(var1, var2)
      #
      # @example IncludeActiveSupportAliases: false (default)
      #   # good
      #   str.starts_with?("a", "b") || str.starts_with?("c")
      #   str.ends_with?(var1) || str.ends_with?(var2)
      #
      #   str.starts_with?("a", "b", "c")
      #   str.ends_with?(var1, var2)
      #
      # @example IncludeActiveSupportAliases: true
      #   # bad
      #   str.starts_with?("a", "b") || str.starts_with?("c")
      #   str.ends_with?(var1) || str.ends_with?(var2)
      #
      #   # good
      #   str.starts_with?("a", "b", "c")
      #   str.ends_with?(var1, var2)
      #
      class DoubleStartEndWith < Base
        extend AutoCorrector

        MSG = 'Use `%<replacement>s` instead of `%<original_code>s`.'

        def on_or(node)
          receiver, method, first_call_args, second_call_args = process_source(node)

          return unless receiver && second_call_args.all?(&:pure?)

          combined_args = combine_args(first_call_args, second_call_args)

          add_offense(node, message: message(node, receiver, first_call_args, method, combined_args)) do |corrector|
            autocorrect(corrector, first_call_args, second_call_args, combined_args)
          end
        end

        private

        def autocorrect(corrector, first_call_args, second_call_args, combined_args)
          first_argument = first_call_args.first.source_range
          last_argument = second_call_args.last.source_range
          range = first_argument.join(last_argument)

          corrector.replace(range, combined_args)
        end

        def process_source(node)
          if check_for_active_support_aliases?
            check_with_active_support_aliases(node)
          else
            two_start_end_with_calls(node)
          end
        end

        def message(node, receiver, first_call_args, method, combined_args)
          dot = first_call_args.first.parent.send_type? ? '.' : '&.'
          replacement = "#{receiver.source}#{dot}#{method}(#{combined_args})"
          format(MSG, replacement: replacement, original_code: node.source)
        end

        def combine_args(first_call_args, second_call_args)
          (first_call_args + second_call_args).map(&:source).join(', ')
        end

        def check_for_active_support_aliases?
          cop_config['IncludeActiveSupportAliases']
        end

        def_node_matcher :two_start_end_with_calls, <<~PATTERN
          (or
            (call $_recv [{:start_with? :end_with?} $_method] $...)
            (call _recv _method $...))
        PATTERN

        def_node_matcher :check_with_active_support_aliases, <<~PATTERN
          (or
            (call $_recv
                    [{:start_with? :starts_with? :end_with? :ends_with?} $_method]
                  $...)
            (call _recv _method $...))
        PATTERN
      end
    end
  end
end
