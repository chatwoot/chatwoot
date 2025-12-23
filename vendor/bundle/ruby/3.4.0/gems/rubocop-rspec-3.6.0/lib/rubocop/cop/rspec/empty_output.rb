# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that the `output` matcher is not called with an empty string.
      #
      # @example
      #   # bad
      #   expect { foo }.to output('').to_stdout
      #   expect { bar }.not_to output('').to_stderr
      #
      #   # good
      #   expect { foo }.not_to output.to_stdout
      #   expect { bar }.to output.to_stderr
      #
      class EmptyOutput < Base
        extend AutoCorrector

        MSG = 'Use `%<runner>s` instead of matching on an empty output.'
        RESTRICT_ON_SEND = Runners.all

        # @!method matching_empty_output(node)
        def_node_matcher :matching_empty_output, <<~PATTERN
          (send
            (block
              (send nil? :expect) ...
            )
            #Runners.all
            (send $(send nil? :output (str empty?)) ...)
          )
        PATTERN

        def on_send(send_node)
          matching_empty_output(send_node) do |node|
            runner = send_node.method?(:to) ? 'not_to' : 'to'
            message = format(MSG, runner: runner)
            add_offense(node, message: message) do |corrector|
              corrector.replace(send_node.loc.selector, runner)
              corrector.replace(node, 'output')
            end
          end
        end
      end
    end
  end
end
