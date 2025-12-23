# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where `sort { |a, b| a.foo <=> b.foo }`
      # can be replaced by `sort_by(&:foo)`.
      # This cop also checks `sort!`, `min`, `max` and `minmax` methods.
      #
      # @example
      #   # bad
      #   array.sort   { |a, b| a.foo <=> b.foo }
      #   array.sort!  { |a, b| a.foo <=> b.foo }
      #   array.max    { |a, b| a.foo <=> b.foo }
      #   array.min    { |a, b| a.foo <=> b.foo }
      #   array.minmax { |a, b| a.foo <=> b.foo }
      #   array.sort   { |a, b| a[:foo] <=> b[:foo] }
      #
      #   # good
      #   array.sort_by(&:foo)
      #   array.sort_by!(&:foo)
      #   array.sort_by { |v| v.foo }
      #   array.sort_by do |var|
      #     var.foo
      #   end
      #   array.max_by(&:foo)
      #   array.min_by(&:foo)
      #   array.minmax_by(&:foo)
      #   array.sort_by { |a| a[:foo] }
      class CompareWithBlock < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<replacement_method>s%<instead>s` instead of ' \
              '`%<compare_method>s { |%<var_a>s, %<var_b>s| %<str_a>s ' \
              '<=> %<str_b>s }`.'

        REPLACEMENT = { sort: :sort_by, sort!: :sort_by!, min: :min_by, max: :max_by, minmax: :minmax_by }.freeze
        private_constant :REPLACEMENT

        def_node_matcher :compare?, <<~PATTERN
          (block
            $(send _ {:sort :sort! :min :max :minmax})
            (args (arg $_a) (arg $_b))
            $send)
        PATTERN

        def_node_matcher :replaceable_body?, <<~PATTERN
          (send
            (send (lvar %1) $_method $...)
            :<=>
            (send (lvar %2) _method $...))
        PATTERN

        def on_block(node)
          compare?(node) do |send, var_a, var_b, body|
            replaceable_body?(body, var_a, var_b) do |method, args_a, args_b|
              return unless slow_compare?(method, args_a, args_b)

              range = compare_range(send, node)

              add_offense(range, message: message(send, method, var_a, var_b, args_a)) do |corrector|
                replacement = if method == :[]
                                "#{REPLACEMENT[send.method_name]} { |a| a[#{args_a.first.source}] }"
                              else
                                "#{REPLACEMENT[send.method_name]}(&:#{method})"
                              end
                corrector.replace(range, replacement)
              end
            end
          end
        end

        private

        def slow_compare?(method, args_a, args_b)
          return false unless args_a == args_b

          if method == :[]
            return false unless args_a.size == 1

            key = args_a.first
            return false unless %i[sym str int].include?(key.type)
          else
            return false unless args_a.empty?
          end
          true
        end

        # rubocop:disable Metrics/MethodLength
        def message(send, method, var_a, var_b, args)
          compare_method     = send.method_name
          replacement_method = REPLACEMENT[compare_method]
          if method == :[]
            key = args.first
            instead = " { |a| a[#{key.source}] }"
            str_a = "#{var_a}[#{key.source}]"
            str_b = "#{var_b}[#{key.source}]"
          else
            instead = "(&:#{method})"
            str_a = "#{var_a}.#{method}"
            str_b = "#{var_b}.#{method}"
          end
          format(MSG, compare_method: compare_method,
                      replacement_method: replacement_method,
                      instead: instead,
                      var_a: var_a,
                      var_b: var_b,
                      str_a: str_a,
                      str_b: str_b)
        end
        # rubocop:enable Metrics/MethodLength

        def compare_range(send, node)
          range_between(send.loc.selector.begin_pos, node.loc.end.end_pos)
        end
      end
    end
  end
end
