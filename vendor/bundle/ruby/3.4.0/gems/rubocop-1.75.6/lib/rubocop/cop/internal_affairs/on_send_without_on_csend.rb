# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks for cops that define `on_send` without define `on_csend`.
      #
      # Although in some cases it can be predetermined that safe navigation
      # will never be used with the code checked by a specific cop, in general
      # it is good practice to handle safe navigation methods if handling any
      # `send` node.
      #
      # NOTE: It is expected to disable this cop for cops that check for method calls
      # on receivers that cannot be nil (`self`, a literal, a constant), and
      # method calls that will never have a receiver (ruby keywords like `raise`,
      # macros like `attr_reader`, DSL methods, etc.), and other checks that wouldn't
      # make sense to support safe navigation.
      #
      # @example
      #   # bad
      #   class MyCop < RuboCop::Cop:Base
      #     def on_send(node)
      #       # ...
      #     end
      #   end
      #
      #   # good - explicit method definition
      #   class MyCop < RuboCop::Cop:Base
      #     def on_send(node)
      #       # ...
      #     end
      #
      #     def on_csend(node)
      #       # ...
      #     end
      #   end
      #
      #   # good - alias
      #   class MyCop < RuboCop::Cop:Base
      #     def on_send(node)
      #       # ...
      #     end
      #     alias on_csend on_send
      #   end
      #
      #   # good - alias_method
      #   class MyCop < RuboCop::Cop:Base
      #     def on_send(node)
      #       # ...
      #     end
      #     alias_method :on_csend, :on_send
      #   end
      class OnSendWithoutOnCSend < Base
        RESTRICT_ON_SEND = %i[alias_method].freeze
        MSG = 'Cop defines `on_send` but not `on_csend`.'

        def on_new_investigation
          @on_send_definition = nil
          @on_csend_definition = nil
        end

        def on_investigation_end
          return unless @on_send_definition && !@on_csend_definition

          add_offense(@on_send_definition)
        end

        def on_def(node)
          @on_send_definition = node if node.method?(:on_send)
          @on_csend_definition = node if node.method?(:on_csend)
        end

        def on_alias(node)
          @on_send_definition = node if node.new_identifier.value == :on_send
          @on_csend_definition = node if node.new_identifier.value == :on_csend
        end

        def on_send(node) # rubocop:disable InternalAffairs/OnSendWithoutOnCSend
          new_identifier = node.first_argument
          return unless new_identifier.basic_literal?

          new_identifier = new_identifier.value

          @on_send_definition = node if new_identifier == :on_send
          @on_csend_definition = node if new_identifier == :on_csend
        end
      end
    end
  end
end
