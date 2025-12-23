module Regexp::Expression
  class Subexpression < Regexp::Expression::Base

    # Traverses the expression, passing each recursive child to the
    # given block.
    # If the block takes two arguments, the indices of the children within
    # their parents are also passed to it.
    def each_expression(include_self = false, &block)
      return enum_for(__method__, include_self) unless block

      if block.arity == 1
        block.call(self) if include_self
        each_expression_without_index(&block)
      else
        block.call(self, 0) if include_self
        each_expression_with_index(&block)
      end
    end

    # Traverses the subexpression (depth-first, pre-order) and calls the given
    # block for each expression with three arguments; the traversal event,
    # the expression, and the index of the expression within its parent.
    #
    # The event argument is passed as follows:
    #
    # - For subexpressions, :enter upon entering the subexpression, and
    #   :exit upon exiting it.
    #
    # - For terminal expressions, :visit is called once.
    #
    # Returns self.
    def traverse(include_self = false, &block)
      return enum_for(__method__, include_self) unless block_given?

      block.call(:enter, self, 0) if include_self

      each_with_index do |exp, index|
        if exp.terminal?
          block.call(:visit, exp, index)
        else
          block.call(:enter, exp, index)
          exp.traverse(&block)
          block.call(:exit, exp, index)
        end
      end

      block.call(:exit, self, 0) if include_self

      self
    end
    alias :walk :traverse

    # Returns a new array with the results of calling the given block once
    # for every expression. If a block is not given, returns an array with
    # each expression and its level index as an array.
    def flat_map(include_self = false, &block)
      case block && block.arity
      when nil then each_expression(include_self).to_a
      when 2   then each_expression(include_self).map(&block)
      else          each_expression(include_self).map { |exp| block.call(exp) }
      end
    end

    protected

    def each_expression_with_index(&block)
      each_with_index do |exp, index|
        block.call(exp, index)
        exp.each_expression_with_index(&block) unless exp.terminal?
      end
    end

    def each_expression_without_index(&block)
      each do |exp|
        block.call(exp)
        exp.each_expression_without_index(&block) unless exp.terminal?
      end
    end
  end
end
