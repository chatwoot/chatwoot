module ReverseMarkdown
  module Converters
    class Ignore < Base
      def convert(node, state = {})
        '' # noop
      end
    end

    register :colgroup, Ignore.new
    register :col,      Ignore.new
    register :head,     Ignore.new
  end
end
