# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks unexpected overrides of the `Struct` built-in methods
      # via `Struct.new`.
      #
      # @example
      #   # bad
      #   Bad = Struct.new(:members, :clone, :count)
      #   b = Bad.new([], true, 1)
      #   b.members #=> [] (overriding `Struct#members`)
      #   b.clone #=> true (overriding `Object#clone`)
      #   b.count #=> 1 (overriding `Enumerable#count`)
      #
      #   # good
      #   Good = Struct.new(:id, :name)
      #   g = Good.new(1, "foo")
      #   g.members #=> [:id, :name]
      #   g.clone #=> #<struct Good id=1, name="foo">
      #   g.count #=> 2
      #
      class StructNewOverride < Base
        MSG = '`%<member_name>s` member overrides `Struct#%<method_name>s` ' \
              'and it may be unexpected.'
        RESTRICT_ON_SEND = %i[new].freeze

        STRUCT_METHOD_NAMES = Struct.instance_methods
        STRUCT_MEMBER_NAME_TYPES = %i[sym str].freeze

        # @!method struct_new(node)
        def_node_matcher :struct_new, <<~PATTERN
          (send
            (const {nil? cbase} :Struct) :new ...)
        PATTERN

        def on_send(node)
          return unless struct_new(node)

          node.arguments.each_with_index do |arg, index|
            # Ignore if the first argument is a class name
            next if index.zero? && arg.str_type?

            # Ignore if the argument is not a member name
            next unless STRUCT_MEMBER_NAME_TYPES.include?(arg.type)

            member_name = arg.value

            next unless STRUCT_METHOD_NAMES.include?(member_name.to_sym)

            message = format(MSG, member_name: member_name.inspect, method_name: member_name.to_s)
            add_offense(arg, message: message)
          end
        end
      end
    end
  end
end
