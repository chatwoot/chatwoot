# frozen_string_literal: true

module RuboCop
  module Cop
    # This class ensures a require statement is present for a standard library
    # determined by the variable library_name
    class RequireLibraryCorrector
      extend RangeHelp

      class << self
        def correct(corrector, node, library_name)
          node = node.parent while node.parent?
          node = node.children.first if node.begin_type?
          corrector.insert_before(node, require_statement(library_name))
        end

        def require_statement(library_name)
          "require '#{library_name}'\n"
        end
      end
    end
  end
end
