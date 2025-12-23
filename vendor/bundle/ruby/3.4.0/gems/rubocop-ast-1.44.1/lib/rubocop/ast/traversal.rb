# frozen_string_literal: true

module RuboCop
  module AST
    # Provides methods for traversing an AST.
    # Does not transform an AST; for that, use Parser::AST::Processor.
    # Override methods to perform custom processing. Remember to call `super`
    # if you want to recursively process descendant nodes.
    module Traversal
      # Only for debugging.
      # @api private
      class DebugError < RuntimeError
      end

      TYPE_TO_METHOD = Hash.new { |h, type| h[type] = :"on_#{type}" }

      def walk(node)
        return if node.nil?

        send(TYPE_TO_METHOD[node.type], node)
        nil
      end

      # @api private
      module CallbackCompiler
        SEND = 'send(TYPE_TO_METHOD[child.type], child)'
        assign_code = 'child = node.children[%<index>i]'
        code = "#{assign_code}\n#{SEND}"
        # How a particular child node should be visited. For example, if a child node
        # can be nil it should be guarded behind a nil check. Or, if a child node is a literal
        # (like a symbol) then the literal itself should not be visited.
        TEMPLATE = {
          skip: '',
          always: code,
          nil?: "#{code} if child"
        }.freeze

        def def_callback(type, *child_node_types,
                         expected_children_count: child_node_types.size..child_node_types.size,
                         body: self.body(child_node_types, expected_children_count))
          type, *aliases = type
          lineno = caller_locations(1, 1).first.lineno
          module_eval(<<~RUBY, __FILE__, lineno)
            def on_#{type}(node)        # def on_send(node)
              #{body}                   #   # body ...
              nil                       #   nil
            end                         # end
          RUBY
          aliases.each do |m|
            alias_method :"on_#{m}", :"on_#{type}"
          end
        end

        def body(child_node_types, expected_children_count)
          visit_children_code =
            child_node_types
            .map.with_index do |child_type, i|
              TEMPLATE.fetch(child_type).gsub('%<index>i', i.to_s)
            end
            .join("\n")

          <<~BODY
            #{children_count_check_code(expected_children_count)}
            #{visit_children_code}
          BODY
        end

        def children_count_check_code(range)
          return '' unless ENV.fetch('RUBOCOP_DEBUG', false)

          <<~RUBY
            n = node.children.size
            raise DebugError, [
              'Expected #{range} children, got',
              n, 'for', node.inspect
            ].join(' ') unless (#{range}).cover?(node.children.size)
          RUBY
        end
      end
      private_constant :CallbackCompiler
      extend CallbackCompiler
      send_code = CallbackCompiler::SEND

      ### children count == 0
      no_children = %i[true false nil self cbase zsuper redo retry
                       forward_args forwarded_args match_nil_pattern
                       forward_arg forwarded_restarg forwarded_kwrestarg
                       lambda empty_else kwnilarg
                       __FILE__ __LINE__ __ENCODING__]

      ### children count == 0..1
      opt_symbol_child = %i[restarg kwrestarg]
      opt_node_child = %i[splat kwsplat match_rest]

      ### children count == 1
      literal_child = %i[int float complex
                         rational str sym lvar
                         ivar cvar gvar nth_ref back_ref
                         arg blockarg shadowarg
                         kwarg match_var]

      many_symbol_children = %i[regopt]

      node_child = %i[not match_current_line defined?
                      arg_expr pin if_guard unless_guard
                      match_with_trailing_comma]
      node_or_nil_child = %i[block_pass preexe postexe]

      NO_CHILD_NODES = (no_children + opt_symbol_child + literal_child).to_set.freeze
      private_constant :NO_CHILD_NODES # Used by Commissioner

      ### children count > 1
      symbol_then_opt_node = %i[lvasgn ivasgn cvasgn gvasgn]
      symbol_then_node_or_nil = %i[optarg kwoptarg]
      node_then_opt_node = %i[while until module sclass]

      ### variable children count
      many_node_children = %i[dstr dsym xstr regexp array hash pair
                              mlhs masgn or_asgn and_asgn rasgn mrasgn
                              undef alias args super yield or and
                              while_post until_post
                              match_with_lvasgn begin kwbegin return
                              in_match match_alt break next
                              match_as array_pattern array_pattern_with_tail
                              hash_pattern const_pattern find_pattern
                              index indexasgn procarg0 kwargs]
      many_opt_node_children = %i[case rescue resbody ensure for when
                                  case_match in_pattern irange erange
                                  match_pattern match_pattern_p iflipflop eflipflop]

      ### Callbacks for above
      def_callback no_children
      def_callback opt_symbol_child, :skip, expected_children_count: 0..1
      def_callback opt_node_child, :nil?, expected_children_count: 0..1

      def_callback literal_child, :skip
      def_callback node_child, :always
      def_callback node_or_nil_child, :nil?

      def_callback symbol_then_opt_node, :skip, :nil?, expected_children_count: 1..2
      def_callback symbol_then_node_or_nil, :skip, :nil?
      def_callback node_then_opt_node, :always, :nil?

      def_callback many_symbol_children, :skip, expected_children_count: (0..)
      def_callback many_node_children, body: <<~RUBY
        node.children.each { |child| #{send_code} }
      RUBY
      def_callback many_opt_node_children,
                   body: <<~RUBY
                     node.children.each { |child| #{send_code} if child }
                   RUBY

      ### Other particular cases
      def_callback :const, :nil?, :skip
      def_callback :casgn, :nil?, :skip, :nil?, expected_children_count: 2..3
      def_callback :class, :always, :nil?, :nil?
      def_callback :def, :skip, :always, :nil?
      def_callback :op_asgn, :always, :skip, :always
      def_callback :if, :always, :nil?, :nil?
      def_callback :block, :always, :always, :nil?
      def_callback :numblock, :always, :skip, :nil?
      def_callback :itblock, :always, :skip, :nil?
      def_callback :defs, :always, :skip, :always, :nil?

      def_callback %i[send csend], body: <<~RUBY
        node.children.each_with_index do |child, i|
          next if i == 1

          #{send_code} if child
        end
      RUBY

      ### generic processing of any other node (forward compatibility)
      defined = instance_methods(false)
                .grep(/^on_/)
                .map { |s| s.to_s[3..].to_sym } # :on_foo => :foo

      to_define = ::Parser::Meta::NODE_TYPES.to_a
      to_define -= defined
      to_define -= %i[numargs itarg ident] # transient
      to_define -= %i[blockarg_expr restarg_expr] # obsolete
      to_define -= %i[objc_kwarg objc_restarg objc_varargs] # mac_ruby
      def_callback to_define, body: <<~RUBY
        node.children.each do |child|
          next unless child.class == Node
          #{send_code}
        end
      RUBY
      MISSING = to_define if ENV['RUBOCOP_DEBUG']
    end
  end
end
