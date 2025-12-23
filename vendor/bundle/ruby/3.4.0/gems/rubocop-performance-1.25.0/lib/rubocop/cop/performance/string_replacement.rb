# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where `gsub` can be replaced by `tr` or `delete`.
      #
      # @example
      #   # bad
      #   'abc'.gsub('b', 'd')
      #   'abc'.gsub('a', '')
      #   'abc'.gsub(/a/, 'd')
      #   'abc'.gsub!('a', 'd')
      #
      #   # good
      #   'abc'.gsub(/.*/, 'a')
      #   'abc'.gsub(/a+/, 'd')
      #   'abc'.tr('b', 'd')
      #   'a b c'.delete(' ')
      class StringReplacement < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[gsub gsub!].freeze
        DETERMINISTIC_REGEX = /\A(?:#{LITERAL_REGEX})+\Z/.freeze
        DELETE = 'delete'
        TR = 'tr'
        BANG = '!'

        def_node_matcher :string_replacement?, <<~PATTERN
          (call _ {:gsub :gsub!}
                    ${regexp str (send (const nil? :Regexp) {:new :compile} _)}
                    $str)
        PATTERN

        def on_send(node)
          string_replacement?(node) do |first_param, second_param|
            return if accept_second_param?(second_param)
            return if accept_first_param?(first_param)

            offense(node, first_param, second_param)
          end
        end
        alias on_csend on_send

        private

        def offense(node, first_param, second_param)
          first_source, = first_source(first_param)
          first_source = interpret_string_escapes(first_source) unless first_param.str_type?
          second_source, = *second_param
          message = message(node, first_source, second_source)

          add_offense(range(node), message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def autocorrect(corrector, node)
          _string, _method, first_param, second_param = *node
          first_source, = first_source(first_param)
          second_source, = *second_param

          first_source = interpret_string_escapes(first_source) unless first_param.str_type?

          replace_method(corrector, node, first_source, second_source, first_param)
        end

        def replace_method(corrector, node, first_source, second_source, first_param)
          replacement_method = replacement_method(node, first_source, second_source)

          corrector.replace(node.loc.selector, replacement_method)
          corrector.replace(first_param, to_string_literal(first_source)) unless first_param.str_type?

          remove_second_param(corrector, node, first_param) if second_source.empty? && first_source.length == 1
        end

        def accept_second_param?(second_param)
          second_source, = *second_param
          second_source.length > 1
        end

        def accept_first_param?(first_param)
          first_source, options = first_source(first_param)
          return true if first_source.nil?

          unless first_param.str_type?
            return true if options
            return true unless first_source.is_a?(String) && first_source =~ DETERMINISTIC_REGEX

            # This must be done after checking DETERMINISTIC_REGEX
            # Otherwise things like \s will trip us up
            first_source = interpret_string_escapes(first_source)
          end

          first_source.length != 1
        end

        def first_source(first_param)
          case first_param.type
          when :regexp
            source_from_regex_literal(first_param)
          when :send
            source_from_regex_constructor(first_param)
          when :str
            first_param.children.first
          end
        end

        def source_from_regex_literal(node)
          regex, options = *node
          source, = *regex
          options, = *options
          [source, options]
        end

        def source_from_regex_constructor(node)
          _const, _init, regex = *node
          case regex.type
          when :regexp
            source_from_regex_literal(regex)
          when :str
            source, = *regex
            source
          end
        end

        def range(node)
          range_between(node.loc.selector.begin_pos, node.source_range.end_pos)
        end

        def replacement_method(node, first_source, second_source)
          replacement = if second_source.empty? && first_source.length == 1
                          DELETE
                        else
                          TR
                        end

          "#{replacement}#{BANG if node.bang_method?}"
        end

        def message(node, first_source, second_source)
          replacement_method = replacement_method(node, first_source, second_source)

          format(MSG, prefer: replacement_method, current: node.method_name)
        end

        def method_suffix(node)
          node.loc.end ? node.loc.end.source : ''
        end

        def remove_second_param(corrector, node, first_param)
          end_range = range_between(first_param.source_range.end_pos, node.source_range.end_pos)

          corrector.replace(end_range, method_suffix(node))
        end
      end
    end
  end
end
