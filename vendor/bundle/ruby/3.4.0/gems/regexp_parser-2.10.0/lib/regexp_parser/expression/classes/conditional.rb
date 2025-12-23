module Regexp::Expression
  module Conditional
    class TooManyBranches < Regexp::Parser::Error
      def initialize
        super('The conditional expression has more than 2 branches')
      end
    end

    class Condition < Regexp::Expression::Base
      # Name or number of the referenced capturing group that determines state.
      # Returns a String if reference is by name, Integer if by number.
      def reference
        ref = text.tr("'<>()", "")
        ref =~ /\D/ ? ref : Integer(ref)
      end
    end

    class Branch < Regexp::Expression::Sequence; end

    class Expression < Regexp::Expression::Subexpression
      def <<(exp)
        expressions.last << exp
      end

      def add_sequence(active_opts = {}, params = { ts: 0 })
        raise TooManyBranches.new if branches.length == 2
        params = params.merge({ conditional_level: conditional_level + 1 })
        Branch.add_to(self, params, active_opts)
      end
      alias :branch :add_sequence

      def condition=(exp)
        expressions.delete(condition)
        expressions.unshift(exp)
      end

      def condition
        find { |subexp| subexp.is_a?(Condition) }
      end

      def branches
        select { |subexp| subexp.is_a?(Sequence) }
      end

      def reference
        condition.reference
      end
    end
  end
end
