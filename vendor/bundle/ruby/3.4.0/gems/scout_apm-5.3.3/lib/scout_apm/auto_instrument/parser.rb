
require 'parser/current'
raise LoadError, "Parser::TreeRewriter was not defined" unless defined?(Parser::TreeRewriter)

module ScoutApm
  module AutoInstrument
    class Cache
      def initialize
        @local_assignments = {}
      end
      
      def local_assignments?(node)
        unless @local_assignments.key?(node)
          if node.type == :lvasgn
            @local_assignments[node] = true
          elsif node.children.find{|child| child.is_a?(Parser::AST::Node) && self.local_assignments?(child)}
            @local_assignments[node] = true
          else
            @local_assignments[node] = false
          end
        end
        
        return @local_assignments[node]
      end
    end
  end
end
