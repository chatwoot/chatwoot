# frozen_string_literal: true

module RuboCop
  module Cop
    module Security
      # Checks for the use of Marshal class methods which have
      # potential security issues leading to remote code execution when
      # loading from an untrusted source.
      #
      # @example
      #   # bad
      #   Marshal.load("{}")
      #   Marshal.restore("{}")
      #
      #   # good
      #   Marshal.dump("{}")
      #
      #   # okish - deep copy hack
      #   Marshal.load(Marshal.dump({}))
      #
      class MarshalLoad < Base
        MSG = 'Avoid using `Marshal.%<method>s`.'
        RESTRICT_ON_SEND = %i[load restore].freeze

        # @!method marshal_load(node)
        def_node_matcher :marshal_load, <<~PATTERN
          (send (const {nil? cbase} :Marshal) ${:load :restore}
          !(send (const {nil? cbase} :Marshal) :dump ...))
        PATTERN

        def on_send(node)
          marshal_load(node) do |method|
            add_offense(node.loc.selector, message: format(MSG, method: method))
          end
        end
      end
    end
  end
end
