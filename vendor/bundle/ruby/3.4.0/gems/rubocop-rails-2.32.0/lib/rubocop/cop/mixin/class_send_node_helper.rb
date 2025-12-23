# frozen_string_literal: true

module RuboCop
  module Cop
    # A mixin to return all of the class send nodes.
    module ClassSendNodeHelper
      def class_send_nodes(class_node)
        class_def = class_node.body

        return [] unless class_def

        if class_def.send_type?
          [class_def]
        else
          class_def.each_child_node(:send)
        end
      end
    end
  end
end
