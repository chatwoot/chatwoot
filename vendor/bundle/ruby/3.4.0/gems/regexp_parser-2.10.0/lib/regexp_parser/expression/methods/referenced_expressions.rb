module Regexp::Expression
  module ReferencedExpressions
    attr_accessor :referenced_expressions

    def referenced_expression
      referenced_expressions && referenced_expressions.first
    end

    def initialize_copy(orig)
      exp_id = [self.class, self.starts_at]

      # prevent infinite recursion for recursive subexp calls
      copied = self.class.instance_eval { @copied_ref_exps ||= {} }
      self.referenced_expressions =
        if copied[exp_id]
          orig.referenced_expressions
        else
          copied[exp_id] = true
          orig.referenced_expressions && orig.referenced_expressions.map(&:dup)
        end
      copied.clear

      super
    end
  end

  Base.include ReferencedExpressions
end
