# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that message expectations are set using spies.
      #
      # This cop can be configured in your configuration using the
      # `EnforcedStyle` option and supports `--auto-gen-config`.
      #
      # @example `EnforcedStyle: have_received` (default)
      #
      #   # bad
      #   expect(foo).to receive(:bar)
      #   do_something
      #
      #   # good
      #   allow(foo).to receive(:bar) # or use instance_spy
      #   do_something
      #   expect(foo).to have_received(:bar)
      #
      # @example `EnforcedStyle: receive`
      #
      #   # bad
      #   allow(foo).to receive(:bar)
      #   do_something
      #   expect(foo).to have_received(:bar)
      #
      #   # good
      #   expect(foo).to receive(:bar)
      #   do_something
      #
      class MessageSpies < Base
        include ConfigurableEnforcedStyle

        MSG_RECEIVE = 'Prefer `receive` for setting message expectations.'

        MSG_HAVE_RECEIVED = 'Prefer `have_received` for setting message ' \
                            'expectations. Setup `%<source>s` as a spy using ' \
                            '`allow` or `instance_spy`.'

        RESTRICT_ON_SEND = Runners.all

        # @!method message_expectation(node)
        def_node_matcher :message_expectation, %(
          (send (send nil? :expect $_) #Runners.all ...)
        )

        # @!method receive_message(node)
        def_node_search :receive_message, %(
          $(send nil? {:receive :have_received} ...)
        )

        def on_send(node)
          receive_message_matcher(node) do |receiver, message_matcher|
            return correct_style_detected if preferred_style?(message_matcher)

            add_offense(
              message_matcher.loc.selector,
              message: error_message(receiver)
            ) { opposite_style_detected }
          end
        end

        private

        def receive_message_matcher(node)
          return unless (receiver = message_expectation(node))

          receive_message(node) { |match| yield(receiver, match) }
        end

        def preferred_style?(expectation)
          expectation.method_name.equal?(style)
        end

        def error_message(receiver)
          case style
          when :receive
            MSG_RECEIVE
          when :have_received
            format(MSG_HAVE_RECEIVED, source: receiver.source)
          else
            # :nocov:
            :noop
            # :nocov:
          end
        end
      end
    end
  end
end
