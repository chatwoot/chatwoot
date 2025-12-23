module ReverseMarkdown
  module Converters
    class Bypass < Base
      def convert(node, state = {})
        treat_children(node, state)
      end
    end

    register :document, Bypass.new
    register :html,     Bypass.new
    register :body,     Bypass.new
    register :span,     Bypass.new
    register :thead,    Bypass.new
    register :tbody,    Bypass.new
    register :tfoot,    Bypass.new
  end
end
