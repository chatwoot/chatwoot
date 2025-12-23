# frozen_string_literal: true

module Prism
  class ParseResult < Result
    # The :line tracepoint event gets fired whenever the Ruby VM encounters an
    # expression on a new line. The types of expressions that can trigger this
    # event are:
    #
    # * if statements
    # * unless statements
    # * nodes that are children of statements lists
    #
    # In order to keep track of the newlines, we have a list of offsets that
    # come back from the parser. We assign these offsets to the first nodes that
    # we find in the tree that are on those lines.
    #
    # Note that the logic in this file should be kept in sync with the Java
    # MarkNewlinesVisitor, since that visitor is responsible for marking the
    # newlines for JRuby/TruffleRuby.
    #
    # This file is autoloaded only when `mark_newlines!` is called, so the
    # re-opening of the various nodes in this file will only be performed in
    # that case. We do that to avoid storing the extra `@newline` instance
    # variable on every node if we don't need it.
    class Newlines < Visitor
      # Create a new Newlines visitor with the given newline offsets.
      def initialize(lines)
        # @type var lines: Integer
        @lines = Array.new(1 + lines, false)
      end

      # Permit block/lambda nodes to mark newlines within themselves.
      def visit_block_node(node)
        old_lines = @lines
        @lines = Array.new(old_lines.size, false)

        begin
          super(node)
        ensure
          @lines = old_lines
        end
      end

      alias_method :visit_lambda_node, :visit_block_node

      # Mark if/unless nodes as newlines.
      def visit_if_node(node)
        node.newline_flag!(@lines)
        super(node)
      end

      alias_method :visit_unless_node, :visit_if_node

      # Permit statements lists to mark newlines within themselves.
      def visit_statements_node(node)
        node.body.each do |child|
          child.newline_flag!(@lines)
        end
        super(node)
      end
    end
  end

  class Node
    def newline_flag? # :nodoc:
      !!defined?(@newline_flag)
    end

    def newline_flag!(lines) # :nodoc:
      line = location.start_line
      unless lines[line]
        lines[line] = true
        @newline_flag = true
      end
    end
  end

  class BeginNode < Node
    def newline_flag!(lines) # :nodoc:
      # Never mark BeginNode with a newline flag, mark children instead.
    end
  end

  class ParenthesesNode < Node
    def newline_flag!(lines) # :nodoc:
      # Never mark ParenthesesNode with a newline flag, mark children instead.
    end
  end

  class IfNode < Node
    def newline_flag!(lines) # :nodoc:
      predicate.newline_flag!(lines)
    end
  end

  class UnlessNode < Node
    def newline_flag!(lines) # :nodoc:
      predicate.newline_flag!(lines)
    end
  end

  class UntilNode < Node
    def newline_flag!(lines) # :nodoc:
      predicate.newline_flag!(lines)
    end
  end

  class WhileNode < Node
    def newline_flag!(lines) # :nodoc:
      predicate.newline_flag!(lines)
    end
  end

  class RescueModifierNode < Node
    def newline_flag!(lines) # :nodoc:
      expression.newline_flag!(lines)
    end
  end

  class InterpolatedMatchLastLineNode < Node
    def newline_flag!(lines) # :nodoc:
      first = parts.first
      first.newline_flag!(lines) if first
    end
  end

  class InterpolatedRegularExpressionNode < Node
    def newline_flag!(lines) # :nodoc:
      first = parts.first
      first.newline_flag!(lines) if first
    end
  end

  class InterpolatedStringNode < Node
    def newline_flag!(lines) # :nodoc:
      first = parts.first
      first.newline_flag!(lines) if first
    end
  end

  class InterpolatedSymbolNode < Node
    def newline_flag!(lines) # :nodoc:
      first = parts.first
      first.newline_flag!(lines) if first
    end
  end

  class InterpolatedXStringNode < Node
    def newline_flag!(lines) # :nodoc:
      first = parts.first
      first.newline_flag!(lines) if first
    end
  end
end
