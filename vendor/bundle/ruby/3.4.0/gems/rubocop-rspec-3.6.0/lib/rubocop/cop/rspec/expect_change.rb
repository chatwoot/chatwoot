# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for consistent style of change matcher.
      #
      # Enforces either passing a receiver and message as method arguments,
      # or a block.
      #
      # This cop can be configured using the `EnforcedStyle` option.
      #
      # @safety
      #   Autocorrection is unsafe because `method_call` style calls the
      #   receiver *once* and sends the message to it before and after
      #   calling the `expect` block, whereas `block` style calls the
      #   expression *twice*, including the receiver.
      #
      #   If your receiver is dynamic (e.g., the result of a method call) and
      #   you expect it to be called before and after the `expect` block,
      #   changing from `block` to `method_call` style may break your test.
      #
      #   [source,ruby]
      #   ----
      #   expect { run }.to change { my_method.message }
      #   # `my_method` is called before and after `run`
      #
      #   expect { run }.to change(my_method, :message)
      #   # `my_method` is called once, but `message` is called on it twice
      #   ----
      #
      # @example `EnforcedStyle: method_call` (default)
      #   # bad
      #   expect { run }.to change { Foo.bar }
      #   expect { run }.to change { foo.baz }
      #
      #   # good
      #   expect { run }.to change(Foo, :bar)
      #   expect { run }.to change(foo, :baz)
      #   # also good when there are arguments or chained method calls
      #   expect { run }.to change { Foo.bar(:count) }
      #   expect { run }.to change { user.reload.name }
      #
      # @example `EnforcedStyle: block`
      #   # bad
      #   expect { run }.to change(Foo, :bar)
      #
      #   # good
      #   expect { run }.to change { Foo.bar }
      #
      class ExpectChange < Base
        extend AutoCorrector
        include ConfigurableEnforcedStyle

        MSG_BLOCK = 'Prefer `change(%<obj>s, :%<attr>s)`.'
        MSG_CALL = 'Prefer `change { %<obj>s.%<attr>s }`.'
        RESTRICT_ON_SEND = %i[change].freeze

        # @!method expect_change_with_arguments(node)
        def_node_matcher :expect_change_with_arguments, <<~PATTERN
          (send nil? :change $_ ({sym str} $_))
        PATTERN

        # @!method expect_change_with_block(node)
        def_node_matcher :expect_change_with_block, <<~PATTERN
          (block
            (send nil? :change)
            (args)
            (send
              ${
                (send nil? _)  # change { user.name }
                const          # change { User.count }
              }
              $_
            )
          )
        PATTERN

        def on_send(node)
          return unless style == :block

          expect_change_with_arguments(node) do |receiver, message|
            msg = format(MSG_CALL, obj: receiver.source, attr: message)
            add_offense(node, message: msg) do |corrector|
              replacement = "change { #{receiver.source}.#{message} }"
              corrector.replace(node, replacement)
            end
          end
        end

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless style == :method_call

          expect_change_with_block(node) do |receiver, message|
            msg = format(MSG_BLOCK, obj: receiver.source, attr: message)
            add_offense(node, message: msg) do |corrector|
              replacement = "change(#{receiver.source}, :#{message})"
              corrector.replace(node, replacement)
            end
          end
        end
      end
    end
  end
end
