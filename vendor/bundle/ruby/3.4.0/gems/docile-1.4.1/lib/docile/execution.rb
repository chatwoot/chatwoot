# frozen_string_literal: true

module Docile
  # @api private
  #
  # A namespace for functions relating to the execution of a block against a
  # proxy object.
  module Execution
    # Execute a block in the context of an object whose methods represent the
    # commands in a DSL, using a specific proxy class.
    #
    # @param dsl        [Object] context object whose methods make up the
    #                            (initial) DSL
    # @param proxy_type [FallbackContextProxy, ChainingFallbackContextProxy]
    #                            which class to instantiate as proxy context
    # @param args       [Array]  arguments to be passed to the block
    # @param block      [Proc]   the block of DSL commands to be executed
    # @return           [Object] the return value of the block
    def exec_in_proxy_context(dsl, proxy_type, *args, &block)
      block_context = eval("self", block.binding) # rubocop:disable Style/EvalWithLocation

      # Use #equal? to test strict object identity (assuming that this dictum
      # from the Ruby docs holds: "[u]nlike ==, the equal? method should never
      # be overridden by subclasses as it is used to determine object
      # identity")
      return dsl.instance_exec(*args, &block) if dsl.equal?(block_context)

      proxy_context = proxy_type.new(dsl, block_context)
      begin
        block_context.instance_variables.each do |ivar|
          value_from_block = block_context.instance_variable_get(ivar)
          proxy_context.instance_variable_set(ivar, value_from_block)
        end

        proxy_context.instance_exec(*args, &block)
      ensure
        if block_context.respond_to?(:__docile_undo_fallback__)
          block_context.send(:__docile_undo_fallback__)
        end

        block_context.instance_variables.each do |ivar|
          next unless proxy_context.instance_variables.include?(ivar)

          value_from_dsl_proxy = proxy_context.instance_variable_get(ivar)
          block_context.instance_variable_set(ivar, value_from_dsl_proxy)
        end
      end
    end

    ruby2_keywords :exec_in_proxy_context if respond_to?(:ruby2_keywords, true)
    module_function :exec_in_proxy_context
  end
end
