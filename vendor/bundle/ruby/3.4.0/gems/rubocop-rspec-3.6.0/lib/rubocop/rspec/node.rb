# frozen_string_literal: true

module RuboCop
  module RSpec
    # RuboCop RSpec specific extensions of RuboCop::AST::Node
    module Node
      # In various cops we want to regard const as literal although it's not
      # strictly literal.
      def recursive_literal_or_const?
        case type
        when :begin, :pair, *AST::Node::COMPOSITE_LITERALS
          children.compact.all?(&:recursive_literal_or_const?)
        else
          literal? || const_type?
        end
      end
    end
  end
end
