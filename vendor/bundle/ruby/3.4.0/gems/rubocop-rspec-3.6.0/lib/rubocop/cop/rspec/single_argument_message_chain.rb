# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that chains of messages contain more than one element.
      #
      # @example
      #   # bad
      #   allow(foo).to receive_message_chain(:bar).and_return(42)
      #
      #   # good
      #   allow(foo).to receive(:bar).and_return(42)
      #
      #   # also good
      #   allow(foo).to receive(:bar, :baz)
      #   allow(foo).to receive("bar.baz")
      #
      class SingleArgumentMessageChain < Base
        extend AutoCorrector

        MSG = 'Use `%<recommended>s` instead of calling ' \
              '`%<called>s` with a single argument.'
        RESTRICT_ON_SEND = %i[receive_message_chain stub_chain].freeze

        # @!method message_chain(node)
        def_node_matcher :message_chain, <<~PATTERN
          (send _ {:receive_message_chain :stub_chain} $_)
        PATTERN

        # @!method single_key_hash?(node)
        def_node_matcher :single_key_hash?, '(hash pair)'

        def on_send(node)
          message_chain(node) do |arg|
            return if valid_usage?(arg)

            method = node.method_name
            msg = format(MSG, recommended: replacement(method), called: method)

            add_offense(node.loc.selector, message: msg) do |corrector|
              autocorrect(corrector, node, method, arg)
            end
          end
        end

        private

        def autocorrect(corrector, node, method, arg)
          corrector.replace(node.loc.selector, replacement(method))
          autocorrect_hash_arg(corrector, arg) if single_key_hash?(arg)
          autocorrect_array_arg(corrector, arg) if arg.array_type?
        end

        def valid_usage?(node)
          return true unless node.literal? || node.array_type?

          case node.type
          when :hash then !single_key_hash?(node)
          when :array then !single_element_array?(node)
          else node.to_s.include?('.')
          end
        end

        def single_element_array?(node)
          node.child_nodes.one?
        end

        def autocorrect_hash_arg(corrector, arg)
          pair = arg.pairs.first
          corrector.replace(arg, key_to_arg(pair.key))
          corrector.insert_after(arg.parent.loc.end,
                                 ".and_return(#{pair.value.source})")
        end

        def autocorrect_array_arg(corrector, arg)
          value = arg.children.first

          corrector.replace(arg, value.source)
        end

        def key_to_arg(node)
          node.sym_type? ? ":#{node.value}" : node.source
        end

        def replacement(method)
          method.equal?(:receive_message_chain) ? 'receive' : 'stub'
        end
      end
    end
  end
end
