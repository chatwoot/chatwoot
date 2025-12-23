# frozen_string_literal: true

module Parser

  class StaticEnvironment
    FORWARD_ARGS = :FORWARD_ARGS

    ANONYMOUS_RESTARG_IN_CURRENT_SCOPE = :ANONYMOUS_RESTARG_IN_CURRENT_SCOPE
    ANONYMOUS_RESTARG_INHERITED = :ANONYMOUS_RESTARG_INHERITED

    ANONYMOUS_KWRESTARG_IN_CURRENT_SCOPE = :ANONYMOUS_KWRESTARG_IN_CURRENT_SCOPE
    ANONYMOUS_KWRESTARG_INHERITED = :ANONYMOUS_KWRESTARG_INHERITED

    ANONYMOUS_BLOCKARG_IN_CURRENT_SCOPE = :ANONYMOUS_BLOCKARG_IN_CURRENT_SCOPE
    ANONYMOUS_BLOCKARG_INHERITED = :ANONYMOUS_BLOCKARG_INHERITED

    def initialize
      reset
    end

    def reset
      @variables = Set[]
      @stack     = []
    end

    def extend_static
      @stack.push(@variables)
      @variables = Set[]

      self
    end

    def extend_dynamic
      @stack.push(@variables)
      @variables = @variables.dup
      if @variables.delete(ANONYMOUS_BLOCKARG_IN_CURRENT_SCOPE)
        @variables.add(ANONYMOUS_BLOCKARG_INHERITED)
      end
      if @variables.delete(ANONYMOUS_RESTARG_IN_CURRENT_SCOPE)
        @variables.add(ANONYMOUS_RESTARG_INHERITED)
      end
      if @variables.delete(ANONYMOUS_KWRESTARG_IN_CURRENT_SCOPE)
        @variables.add(ANONYMOUS_KWRESTARG_INHERITED)
      end

      self
    end

    def unextend
      @variables = @stack.pop

      self
    end

    def declare(name)
      @variables.add(name.to_sym)

      self
    end

    def declared?(name)
      @variables.include?(name.to_sym)
    end

    # Forward args

    def declare_forward_args
      declare(FORWARD_ARGS)
    end

    def declared_forward_args?
      declared?(FORWARD_ARGS)
    end

    # Anonymous blockarg

    def declare_anonymous_blockarg
      declare(ANONYMOUS_BLOCKARG_IN_CURRENT_SCOPE)
    end

    def declared_anonymous_blockarg?
      declared?(ANONYMOUS_BLOCKARG_IN_CURRENT_SCOPE) || declared?(ANONYMOUS_BLOCKARG_INHERITED)
    end

    def declared_anonymous_blockarg_in_current_scpe?
      declared?(ANONYMOUS_BLOCKARG_IN_CURRENT_SCOPE)
    end

    def parent_has_anonymous_blockarg?
      @stack.any? { |variables| variables.include?(ANONYMOUS_BLOCKARG_IN_CURRENT_SCOPE) }
    end

    # Anonymous restarg

    def declare_anonymous_restarg
      declare(ANONYMOUS_RESTARG_IN_CURRENT_SCOPE)
    end

    def declared_anonymous_restarg?
      declared?(ANONYMOUS_RESTARG_IN_CURRENT_SCOPE) || declared?(ANONYMOUS_RESTARG_INHERITED)
    end

    def declared_anonymous_restarg_in_current_scope?
      declared?(ANONYMOUS_RESTARG_IN_CURRENT_SCOPE)
    end

    def parent_has_anonymous_restarg?
      @stack.any? { |variables| variables.include?(ANONYMOUS_RESTARG_IN_CURRENT_SCOPE) }
    end

    # Anonymous kwresarg

    def declare_anonymous_kwrestarg
      declare(ANONYMOUS_KWRESTARG_IN_CURRENT_SCOPE)
    end

    def declared_anonymous_kwrestarg?
      declared?(ANONYMOUS_KWRESTARG_IN_CURRENT_SCOPE) || declared?(ANONYMOUS_KWRESTARG_INHERITED)
    end

    def declared_anonymous_kwrestarg_in_current_scope?
      declared?(ANONYMOUS_KWRESTARG_IN_CURRENT_SCOPE)
    end

    def parent_has_anonymous_kwrestarg?
      @stack.any? { |variables| variables.include?(ANONYMOUS_KWRESTARG_IN_CURRENT_SCOPE) }
    end

    def empty?
      @stack.empty?
    end
  end

end
