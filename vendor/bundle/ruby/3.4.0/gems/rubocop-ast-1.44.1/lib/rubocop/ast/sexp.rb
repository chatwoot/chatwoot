# frozen_string_literal: true

module RuboCop
  module AST
    # This module provides a shorthand method to create a {Node} like
    # `Parser::AST::Sexp`.
    #
    # @see https://www.rubydoc.info/gems/ast/AST/Sexp
    module Sexp
      # Creates a {Node} with type `type` and children `children`.
      def s(type, *children)
        klass = Builder::NODE_MAP[type] || Node
        klass.new(type, children)
      end
    end
  end
end
