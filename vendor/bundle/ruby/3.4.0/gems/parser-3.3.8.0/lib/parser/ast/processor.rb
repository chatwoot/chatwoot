# frozen_string_literal: true

module Parser
  module AST

    ##
    # @api public
    #
    class Processor
      include ::AST::Processor::Mixin

      def process_regular_node(node)
        node.updated(nil, process_all(node))
      end

      alias on_dstr     process_regular_node
      alias on_dsym     process_regular_node
      alias on_regexp   process_regular_node
      alias on_xstr     process_regular_node
      alias on_splat    process_regular_node
      alias on_kwsplat  process_regular_node
      alias on_array    process_regular_node
      alias on_pair     process_regular_node
      alias on_hash     process_regular_node
      alias on_kwargs   process_regular_node
      alias on_irange   process_regular_node
      alias on_erange   process_regular_node

      def on_var(node)
        node
      end

      # @private
      def process_variable_node(node)
        on_var(node)
      end

      alias on_lvar     process_variable_node
      alias on_ivar     process_variable_node
      alias on_gvar     process_variable_node
      alias on_cvar     process_variable_node
      alias on_back_ref process_variable_node
      alias on_nth_ref  process_variable_node

      def on_vasgn(node)
        name, value_node = *node

        if !value_node.nil?
          node.updated(nil, [
            name, process(value_node)
          ])
        else
          node
        end
      end

      # @private
      def process_var_asgn_node(node)
        on_vasgn(node)
      end

      alias on_lvasgn   process_var_asgn_node
      alias on_ivasgn   process_var_asgn_node
      alias on_gvasgn   process_var_asgn_node
      alias on_cvasgn   process_var_asgn_node

      alias on_and_asgn process_regular_node
      alias on_or_asgn  process_regular_node

      def on_op_asgn(node)
        var_node, method_name, value_node = *node

        node.updated(nil, [
          process(var_node), method_name, process(value_node)
        ])
      end

      alias on_mlhs     process_regular_node
      alias on_masgn    process_regular_node

      def on_const(node)
        scope_node, name = *node

        node.updated(nil, [
          process(scope_node), name
        ])
      end

      def on_casgn(node)
        scope_node, name, value_node = *node

        if !value_node.nil?
          node.updated(nil, [
            process(scope_node), name, process(value_node)
          ])
        else
          node.updated(nil, [
            process(scope_node), name
          ])
        end
      end

      alias on_args     process_regular_node

      def on_argument(node)
        arg_name, value_node = *node

        if !value_node.nil?
          node.updated(nil, [
            arg_name, process(value_node)
          ])
        else
          node
        end
      end

      # @private
      def process_argument_node(node)
        on_argument(node)
      end

      alias on_arg            process_argument_node
      alias on_optarg         process_argument_node
      alias on_restarg        process_argument_node
      alias on_blockarg       process_argument_node
      alias on_shadowarg      process_argument_node
      alias on_kwarg          process_argument_node
      alias on_kwoptarg       process_argument_node
      alias on_kwrestarg      process_argument_node
      alias on_forward_arg    process_argument_node

      def on_procarg0(node)
        if node.children[0].is_a?(Symbol)
          # This branch gets executed when the builder
          # is not configured to emit and 'arg' inside 'procarg0', i.e. when
          #   Parser::Builders::Default.emit_arg_inside_procarg0
          # is set to false.
          #
          # If this flag is set to true this branch is unreachable.
          # s(:procarg0, :a)
          on_argument(node)
        else
          # s(:procarg0, s(:arg, :a), s(:arg, :b))
          process_regular_node(node)
        end
      end

      alias on_arg_expr       process_regular_node
      alias on_restarg_expr   process_regular_node
      alias on_blockarg_expr  process_regular_node
      alias on_block_pass     process_regular_node

      alias on_forwarded_restarg   process_regular_node
      alias on_forwarded_kwrestarg process_regular_node

      alias on_module         process_regular_node
      alias on_class          process_regular_node
      alias on_sclass         process_regular_node

      def on_def(node)
        name, args_node, body_node = *node

        node.updated(nil, [
          name,
          process(args_node), process(body_node)
        ])
      end

      def on_defs(node)
        definee_node, name, args_node, body_node = *node

        node.updated(nil, [
          process(definee_node), name,
          process(args_node), process(body_node)
        ])
      end

      alias on_undef    process_regular_node
      alias on_alias    process_regular_node

      def on_send(node)
        receiver_node, method_name, *arg_nodes = *node

        receiver_node = process(receiver_node) if receiver_node
        node.updated(nil, [
          receiver_node, method_name, *process_all(arg_nodes)
        ])
      end

      alias on_csend on_send

      alias on_index     process_regular_node
      alias on_indexasgn process_regular_node

      alias on_block    process_regular_node
      alias on_lambda   process_regular_node

      def on_numblock(node)
        method_call, max_numparam, body = *node

        node.updated(nil, [
          process(method_call), max_numparam, process(body)
        ])
      end

      alias on_while      process_regular_node
      alias on_while_post process_regular_node
      alias on_until      process_regular_node
      alias on_until_post process_regular_node
      alias on_for        process_regular_node

      alias on_return   process_regular_node
      alias on_break    process_regular_node
      alias on_next     process_regular_node
      alias on_redo     process_regular_node
      alias on_retry    process_regular_node
      alias on_super    process_regular_node
      alias on_yield    process_regular_node
      alias on_defined? process_regular_node

      alias on_not      process_regular_node
      alias on_and      process_regular_node
      alias on_or       process_regular_node

      alias on_if       process_regular_node

      alias on_when     process_regular_node
      alias on_case     process_regular_node

      alias on_iflipflop process_regular_node
      alias on_eflipflop process_regular_node

      alias on_match_current_line process_regular_node
      alias on_match_with_lvasgn  process_regular_node

      alias on_resbody  process_regular_node
      alias on_rescue   process_regular_node
      alias on_ensure   process_regular_node

      alias on_begin    process_regular_node
      alias on_kwbegin  process_regular_node

      alias on_preexe   process_regular_node
      alias on_postexe  process_regular_node

      alias on_case_match              process_regular_node
      alias on_in_match                process_regular_node
      alias on_match_pattern           process_regular_node
      alias on_match_pattern_p         process_regular_node
      alias on_in_pattern              process_regular_node
      alias on_if_guard                process_regular_node
      alias on_unless_guard            process_regular_node
      alias on_match_var               process_variable_node
      alias on_match_rest              process_regular_node
      alias on_pin                     process_regular_node
      alias on_match_alt               process_regular_node
      alias on_match_as                process_regular_node
      alias on_array_pattern           process_regular_node
      alias on_array_pattern_with_tail process_regular_node
      alias on_hash_pattern            process_regular_node
      alias on_const_pattern           process_regular_node
      alias on_find_pattern            process_regular_node

      # @private
      def process_variable_node(node)
        warn 'Parser::AST::Processor#process_variable_node is deprecated as a' \
          ' public API and will be removed. Please use ' \
          'Parser::AST::Processor#on_var instead.'
        on_var(node)
      end

      # @private
      def process_var_asgn_node(node)
        warn 'Parser::AST::Processor#process_var_asgn_node is deprecated as a' \
          ' public API and will be removed. Please use ' \
          'Parser::AST::Processor#on_vasgn instead.'
        on_vasgn(node)
      end

      # @private
      def process_argument_node(node)
        warn 'Parser::AST::Processor#process_argument_node is deprecated as a' \
          ' public API and will be removed. Please use ' \
          'Parser::AST::Processor#on_argument instead.'
        on_argument(node)
      end

      def on_empty_else(node)
        node
      end
    end
  end
end
