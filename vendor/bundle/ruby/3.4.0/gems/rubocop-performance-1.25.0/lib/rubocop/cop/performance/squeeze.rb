# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies places where `gsub(/a+/, 'a')` and `gsub!(/a+/, 'a')`
      # can be replaced by `squeeze('a')` and `squeeze!('a')`.
      #
      # The `squeeze('a')` method is faster than `gsub(/a+/, 'a')`.
      #
      # @example
      #
      #   # bad
      #   str.gsub(/a+/, 'a')
      #   str.gsub!(/a+/, 'a')
      #
      #   # good
      #   str.squeeze('a')
      #   str.squeeze!('a')
      #
      class Squeeze < Base
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[gsub gsub!].freeze

        PREFERRED_METHODS = { gsub: :squeeze, gsub!: :squeeze! }.freeze

        def_node_matcher :squeeze_candidate?, <<~PATTERN
          (call
            $!nil? ${:gsub :gsub!}
            (regexp
              (str $#repeating_literal?)
              (regopt))
            (str $_))
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_send(node)
          squeeze_candidate?(node) do |receiver, bad_method, regexp_str, replace_str|
            regexp_str = regexp_str[0..-2] # delete '+' from the end
            regexp_str = interpret_string_escapes(regexp_str)
            return unless replace_str == regexp_str

            good_method = PREFERRED_METHODS[bad_method]
            message = format(MSG, current: bad_method, prefer: good_method)

            add_offense(node.loc.selector, message: message) do |corrector|
              # FIXME: When requiring only RuboCop 1.70.0 and above,
              # `dup` in `replace_str.dup` becomes unnecessary, as
              # frozen strings are handled in the `to_string_literal`
              # implementation. Please remove it.
              string_literal = to_string_literal(replace_str.dup)
              new_code = "#{receiver.source}#{node.loc.dot.source}#{good_method}(#{string_literal})"

              corrector.replace(node, new_code)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize
        alias on_csend on_send

        private

        def repeating_literal?(regex_str)
          regex_str.match?(/\A(?:#{Util::LITERAL_REGEX})\+\z/o)
        end
      end
    end
  end
end
