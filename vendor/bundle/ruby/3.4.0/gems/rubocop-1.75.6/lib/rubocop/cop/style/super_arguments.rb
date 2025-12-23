# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant argument forwarding when calling super with arguments identical to
      # the method definition.
      #
      # Using zero arity `super` within a `define_method` block results in `RuntimeError`:
      #
      # [source,ruby]
      # ----
      # def m
      #   define_method(:foo) { super() } # => OK
      # end
      #
      # def m
      #   define_method(:foo) { super }   # => RuntimeError
      # end
      # ----
      #
      # Furthermore, any arguments accompanied by a block may potentially be delegating to
      # `define_method`, therefore, `super` used within these blocks will be allowed.
      # This approach might result in false negatives, yet ensuring safe detection takes precedence.
      #
      # NOTE: When forwarding the same arguments but replacing the block argument with a new inline
      # block, it is not necessary to explicitly list the non-block arguments. As such, an offense
      # will be registered in this case.
      #
      # @example
      #   # bad
      #   def method(*args, **kwargs)
      #     super(*args, **kwargs)
      #   end
      #
      #   # good - implicitly passing all arguments
      #   def method(*args, **kwargs)
      #     super
      #   end
      #
      #   # good - forwarding a subset of the arguments
      #   def method(*args, **kwargs)
      #     super(*args)
      #   end
      #
      #   # good - forwarding no arguments
      #   def method(*args, **kwargs)
      #     super()
      #   end
      #
      #   # bad - forwarding with overridden block
      #   def method(*args, **kwargs, &block)
      #     super(*args, **kwargs) { do_something }
      #   end
      #
      #   # good - implicitly passing all non-block arguments
      #   def method(*args, **kwargs, &block)
      #     super { do_something }
      #   end
      #
      #   # good - assigning to the block variable before calling super
      #   def method(&block)
      #     # Assigning to the block variable would pass the old value to super,
      #     # under this circumstance the block must be referenced explicitly.
      #     block ||= proc { 'fallback behavior' }
      #     super(&block)
      #   end
      class SuperArguments < Base
        extend AutoCorrector

        ASSIGN_TYPES = %i[or_asgn lvasgn].freeze

        MSG = 'Call `super` without arguments and parentheses when the signature is identical.'
        MSG_INLINE_BLOCK = 'Call `super` without arguments and parentheses when all positional ' \
                           'and keyword arguments are forwarded.'

        def on_super(super_node)
          return unless (def_node = find_def_node(super_node))

          def_node_args = def_node.arguments.argument_list
          super_args = preprocess_super_args(super_node.arguments)

          return unless arguments_identical?(def_node, super_node, def_node_args, super_args)

          # If the number of arguments to the def node and super node are different here,
          # it's because the block argument is not forwarded.
          message = def_node_args.size == super_args.size ? MSG : MSG_INLINE_BLOCK
          add_offense(super_node, message: message) do |corrector|
            corrector.replace(super_node, 'super')
          end
        end

        private

        def find_def_node(super_node)
          super_node.ancestors.find do |node|
            # When defining dynamic methods, implicitly calling `super` is not possible.
            # Since there is a possibility of delegation to `define_method`,
            # `super` used within the block is always allowed.
            break if node.any_block_type? && !block_sends_to_super?(super_node, node)

            break node if node.any_def_type?
          end
        end

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def arguments_identical?(def_node, super_node, def_args, super_args)
          return false if argument_list_size_differs?(def_args, super_args, super_node)

          def_args.zip(super_args).each do |def_arg, super_arg|
            next if positional_arg_same?(def_arg, super_arg)
            next if positional_rest_arg_same(def_arg, super_arg)
            next if keyword_arg_same?(def_arg, super_arg)
            next if keyword_rest_arg_same?(def_arg, super_arg)
            next if block_arg_same?(def_node, super_node, def_arg, super_arg)
            next if forward_arg_same?(def_arg, super_arg)

            return false
          end

          true
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def argument_list_size_differs?(def_args, super_args, super_node)
          # If the def node has a block argument and the super node has an explicit block,
          # the number of arguments is the same, so ignore the def node block arg.
          def_args_size = def_args.size
          def_args_size -= 1 if def_args.any?(&:blockarg_type?) && block_sends_to_super?(super_node)

          def_args_size != super_args.size
        end

        def block_sends_to_super?(super_node, parent_node = super_node.parent)
          # Checks if the send node of a block is the given super node,
          # or a method chain containing it.
          return false unless parent_node
          return false unless parent_node.any_block_type?

          parent_node.send_node.each_node(:super).any?(super_node)
        end

        def positional_arg_same?(def_arg, super_arg)
          return false unless def_arg.type?(:arg, :optarg)
          return false unless super_arg.lvar_type?

          def_arg.name == super_arg.children.first
        end

        def positional_rest_arg_same(def_arg, super_arg)
          return false unless def_arg.restarg_type?
          # anonymous forwarding
          return true if def_arg.name.nil? && super_arg.forwarded_restarg_type?
          return false unless super_arg.splat_type?
          return false unless (lvar_node = super_arg.children.first).lvar_type?

          def_arg.name == lvar_node.children.first
        end

        def keyword_arg_same?(def_arg, super_arg)
          return false unless def_arg.type?(:kwarg, :kwoptarg)
          return false unless (pair_node = super_arg).pair_type?
          return false unless (sym_node = pair_node.key).sym_type?
          return false unless (lvar_node = pair_node.value).lvar_type?
          return false unless sym_node.source == lvar_node.source

          def_arg.name == sym_node.value
        end

        def keyword_rest_arg_same?(def_arg, super_arg)
          return false unless def_arg.kwrestarg_type?
          # anonymous forwarding
          return true if def_arg.name.nil? && super_arg.forwarded_kwrestarg_type?
          return false unless super_arg.kwsplat_type?
          return false unless (lvar_node = super_arg.children.first).lvar_type?

          def_arg.name == lvar_node.children.first
        end

        def block_arg_same?(def_node, super_node, def_arg, super_arg)
          return false unless def_arg.blockarg_type?
          return true if block_sends_to_super?(super_node)
          return false unless super_arg.block_pass_type?

          # anonymous forwarding
          return true if (block_pass_child = super_arg.children.first).nil? && def_arg.name.nil?

          block_arg_name = block_pass_child.children.first
          def_arg.name == block_arg_name && !block_reassigned?(def_node, block_arg_name)
        end

        # Reassigning the block argument will still pass along the original block to super
        # https://bugs.ruby-lang.org/issues/20505
        def block_reassigned?(def_node, block_arg_name)
          def_node.each_node(*ASSIGN_TYPES).any? do |assign_node|
            # TODO: Since `Symbol#name` is supported from Ruby 3.0, the inheritance check for
            # `AST::Node` can be removed when requiring Ruby 3.0+.
            lhs = assign_node.node_parts[0]
            next if lhs.is_a?(AST::Node) && !lhs.respond_to?(:name)

            assign_node.name == block_arg_name
          end
        end

        def forward_arg_same?(def_arg, super_arg)
          def_arg.forward_arg_type? && super_arg.forwarded_args_type?
        end

        def preprocess_super_args(super_args)
          super_args.flat_map do |node|
            if node.hash_type? && !node.braces?
              node.children
            else
              node
            end
          end
        end
      end
    end
  end
end
