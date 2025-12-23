# frozen_string_literal: true

module RuboCop
  module Cop
    module Security
      # Checks for the use of `Kernel#open` and `URI.open` with dynamic
      # data.
      #
      # `Kernel#open` and `URI.open` enable not only file access but also process
      # invocation by prefixing a pipe symbol (e.g., `open("| ls")`).
      # So, it may lead to a serious security risk by using variable input to
      # the argument of `Kernel#open` and `URI.open`. It would be better to use
      # `File.open`, `IO.popen` or `URI.parse#open` explicitly.
      #
      # NOTE: `open` and `URI.open` with literal strings are not flagged by this
      # cop.
      #
      # @safety
      #   This cop could register false positives if `open` is redefined
      #   in a class and then used without a receiver in that class.
      #
      # @example
      #   # bad
      #   open(something)
      #   open("| #{something}")
      #   open("| foo")
      #   URI.open(something)
      #
      #   # good
      #   File.open(something)
      #   IO.popen(something)
      #   URI.parse(something).open
      #
      #   # good (literal strings)
      #   open("foo.text")
      #   URI.open("http://example.com")
      class Open < Base
        MSG = 'The use of `%<receiver>sopen` is a serious security risk.'
        RESTRICT_ON_SEND = %i[open].freeze

        # @!method open?(node)
        def_node_matcher :open?, <<~PATTERN
          (send ${nil? (const {nil? cbase} :URI)} :open $_ ...)
        PATTERN

        def on_send(node)
          open?(node) do |receiver, code|
            return if safe?(code)

            message = format(MSG, receiver: receiver ? "#{receiver.source}." : 'Kernel#')
            add_offense(node.loc.selector, message: message)
          end
        end

        private

        def safe?(node)
          if simple_string?(node)
            safe_argument?(node.str_content)
          elsif composite_string?(node)
            safe?(node.children.first)
          else
            false
          end
        end

        def safe_argument?(argument)
          !argument.empty? && !argument.start_with?('|')
        end

        def simple_string?(node)
          node.str_type?
        end

        def composite_string?(node)
          interpolated_string?(node) || concatenated_string?(node)
        end

        def interpolated_string?(node)
          node.dstr_type?
        end

        def concatenated_string?(node)
          node.send_type? && node.method?(:+) && node.receiver.str_type?
        end
      end
    end
  end
end
