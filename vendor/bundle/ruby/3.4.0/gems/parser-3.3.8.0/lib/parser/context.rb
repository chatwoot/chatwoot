# frozen_string_literal: true

module Parser
  # Context of parsing that is represented by a stack of scopes.
  #
  # Supported states:
  # + :class - in the class body (class A; end)
  # + :module - in the module body (module M; end)
  # + :sclass - in the singleton class body (class << obj; end)
  # + :def - in the method body (def m; end)
  # + :defs - in the singleton method body (def self.m; end)
  # + :def_open_args - in the arglist of the method definition
  #                    keep in mind that it's set **only** after reducing the first argument,
  #                    if you need to handle the first argument check `lex_state == expr_fname`
  # + :block - in the block body (tap {})
  # + :lambda - in the lambda body (-> {})
  #
  class Context
    FLAGS = %i[
      in_defined
      in_kwarg
      in_argdef
      in_def
      in_class
      in_block
      in_lambda
      cant_return
    ]

    def initialize
      reset
    end

    def reset
      @in_defined = false
      @in_kwarg = false
      @in_argdef = false
      @in_def = false
      @in_class = false
      @in_block = false
      @in_lambda = false
      @cant_return = false
    end

    attr_accessor(*FLAGS)

    def in_dynamic_block?
      in_block || in_lambda
    end
  end
end
