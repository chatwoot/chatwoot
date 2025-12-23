# frozen_string_literal: true

begin
  require "ruby_parser"
rescue LoadError
  warn(%q{Error: Unable to load ruby_parser. Add `gem "ruby_parser"` to your Gemfile.})
  exit(1)
end

module Prism
  module Translation
    # This module is the entry-point for converting a prism syntax tree into the
    # seattlerb/ruby_parser gem's syntax tree.
    class RubyParser
      # A prism visitor that builds Sexp objects.
      class Compiler < ::Prism::Compiler
        # This is the name of the file that we are compiling. We set it on every
        # Sexp object that is generated, and also use it to compile __FILE__
        # nodes.
        attr_reader :file

        # Class variables will change their type based on if they are inside of
        # a method definition or not, so we need to track that state.
        attr_reader :in_def

        # Some nodes will change their representation if they are inside of a
        # pattern, so we need to track that state.
        attr_reader :in_pattern

        # Initialize a new compiler with the given file name.
        def initialize(file, in_def: false, in_pattern: false)
          @file = file
          @in_def = in_def
          @in_pattern = in_pattern
        end

        # alias foo bar
        # ^^^^^^^^^^^^^
        def visit_alias_method_node(node)
          s(node, :alias, visit(node.new_name), visit(node.old_name))
        end

        # alias $foo $bar
        # ^^^^^^^^^^^^^^^
        def visit_alias_global_variable_node(node)
          s(node, :valias, node.new_name.name, node.old_name.name)
        end

        # foo => bar | baz
        #        ^^^^^^^^^
        def visit_alternation_pattern_node(node)
          s(node, :or, visit(node.left), visit(node.right))
        end

        # a and b
        # ^^^^^^^
        def visit_and_node(node)
          left = visit(node.left)

          if left[0] == :and
            # ruby_parser has the and keyword as right-associative as opposed to
            # prism which has it as left-associative. We reverse that
            # associativity here.
            nest = left
            nest = nest[2] while nest[2][0] == :and
            nest[2] = s(node, :and, nest[2], visit(node.right))
            left
          else
            s(node, :and, left, visit(node.right))
          end
        end

        # []
        # ^^
        def visit_array_node(node)
          if in_pattern
            s(node, :array_pat, nil).concat(visit_all(node.elements))
          else
            s(node, :array).concat(visit_all(node.elements))
          end
        end

        # foo => [bar]
        #        ^^^^^
        def visit_array_pattern_node(node)
          if node.constant.nil? && node.requireds.empty? && node.rest.nil? && node.posts.empty?
            s(node, :array_pat)
          else
            result = s(node, :array_pat, visit_pattern_constant(node.constant)).concat(visit_all(node.requireds))

            case node.rest
            when SplatNode
              result << :"*#{node.rest.expression&.name}"
            when ImplicitRestNode
              result << :*

              # This doesn't make any sense at all, but since we're trying to
              # replicate the behavior directly, we'll copy it.
              result.line(666)
            end

            result.concat(visit_all(node.posts))
          end
        end

        # foo(bar)
        #     ^^^
        def visit_arguments_node(node)
          raise "Cannot visit arguments directly"
        end

        # { a: 1 }
        #   ^^^^
        def visit_assoc_node(node)
          [visit(node.key), visit(node.value)]
        end

        # def foo(**); bar(**); end
        #                  ^^
        #
        # { **foo }
        #   ^^^^^
        def visit_assoc_splat_node(node)
          if node.value.nil?
            [s(node, :kwsplat)]
          else
            [s(node, :kwsplat, visit(node.value))]
          end
        end

        # $+
        # ^^
        def visit_back_reference_read_node(node)
          s(node, :back_ref, node.name.name.delete_prefix("$").to_sym)
        end

        # begin end
        # ^^^^^^^^^
        def visit_begin_node(node)
          result = node.statements.nil? ? s(node, :nil) : visit(node.statements)

          if !node.rescue_clause.nil?
            if !node.statements.nil?
              result = s(node.statements, :rescue, result, visit(node.rescue_clause))
            else
              result = s(node.rescue_clause, :rescue, visit(node.rescue_clause))
            end

            current = node.rescue_clause
            until (current = current.subsequent).nil?
              result << visit(current)
            end
          end

          if !node.else_clause&.statements.nil?
            result << visit(node.else_clause)
          end

          if !node.ensure_clause.nil?
            if !node.statements.nil? || !node.rescue_clause.nil? || !node.else_clause.nil?
              result = s(node.statements || node.rescue_clause || node.else_clause || node.ensure_clause, :ensure, result, visit(node.ensure_clause))
            else
              result = s(node.ensure_clause, :ensure, visit(node.ensure_clause))
            end
          end

          result
        end

        # foo(&bar)
        #     ^^^^
        def visit_block_argument_node(node)
          s(node, :block_pass).tap do |result|
            result << visit(node.expression) unless node.expression.nil?
          end
        end

        # foo { |; bar| }
        #          ^^^
        def visit_block_local_variable_node(node)
          node.name
        end

        # A block on a keyword or method call.
        def visit_block_node(node)
          s(node, :block_pass, visit(node.expression))
        end

        # def foo(&bar); end
        #         ^^^^
        def visit_block_parameter_node(node)
          :"&#{node.name}"
        end

        # A block's parameters.
        def visit_block_parameters_node(node)
          # If this block parameters has no parameters and is using pipes, then
          # it inherits its location from its shadow locals, even if they're not
          # on the same lines as the pipes.
          shadow_loc = true

          result =
            if node.parameters.nil?
              s(node, :args)
            else
              shadow_loc = false
              visit(node.parameters)
            end

          if node.opening == "("
            result.line = node.opening_loc.start_line
            result.line_max = node.closing_loc.end_line
            shadow_loc = false
          end

          if node.locals.any?
            shadow = s(node, :shadow).concat(visit_all(node.locals))
            shadow.line = node.locals.first.location.start_line
            shadow.line_max = node.locals.last.location.end_line
            result << shadow

            if shadow_loc
              result.line = shadow.line
              result.line_max = shadow.line_max
            end
          end

          result
        end

        # break
        # ^^^^^
        #
        # break foo
        # ^^^^^^^^^
        def visit_break_node(node)
          if node.arguments.nil?
            s(node, :break)
          elsif node.arguments.arguments.length == 1
            s(node, :break, visit(node.arguments.arguments.first))
          else
            s(node, :break, s(node.arguments, :array).concat(visit_all(node.arguments.arguments)))
          end
        end

        # foo
        # ^^^
        #
        # foo.bar
        # ^^^^^^^
        #
        # foo.bar() {}
        # ^^^^^^^^^^^^
        def visit_call_node(node)
          case node.name
          when :!~
            return s(node, :not, visit(node.copy(name: :"=~")))
          when :=~
            if node.arguments&.arguments&.length == 1 && node.block.nil?
              case node.receiver
              when StringNode
                return s(node, :match3, visit(node.arguments.arguments.first), visit(node.receiver))
              when RegularExpressionNode, InterpolatedRegularExpressionNode
                return s(node, :match2, visit(node.receiver), visit(node.arguments.arguments.first))
              end

              case node.arguments.arguments.first
              when RegularExpressionNode, InterpolatedRegularExpressionNode
                return s(node, :match3, visit(node.arguments.arguments.first), visit(node.receiver))
              end
            end
          end

          type = node.attribute_write? ? :attrasgn : :call
          type = :"safe_#{type}" if node.safe_navigation?

          arguments = node.arguments&.arguments || []
          write_value = arguments.pop if type == :attrasgn
          block = node.block

          if block.is_a?(BlockArgumentNode)
            arguments << block
            block = nil
          end

          result = s(node, type, visit(node.receiver), node.name).concat(visit_all(arguments))
          result << visit_write_value(write_value) unless write_value.nil?

          visit_block(node, result, block)
        end

        # foo.bar += baz
        # ^^^^^^^^^^^^^^^
        def visit_call_operator_write_node(node)
          if op_asgn?(node)
            s(node, op_asgn_type(node, :op_asgn), visit(node.receiver), visit_write_value(node.value), node.read_name, node.binary_operator)
          else
            s(node, op_asgn_type(node, :op_asgn2), visit(node.receiver), node.write_name, node.binary_operator, visit_write_value(node.value))
          end
        end

        # foo.bar &&= baz
        # ^^^^^^^^^^^^^^^
        def visit_call_and_write_node(node)
          if op_asgn?(node)
            s(node, op_asgn_type(node, :op_asgn), visit(node.receiver), visit_write_value(node.value), node.read_name, :"&&")
          else
            s(node, op_asgn_type(node, :op_asgn2), visit(node.receiver), node.write_name, :"&&", visit_write_value(node.value))
          end
        end

        # foo.bar ||= baz
        # ^^^^^^^^^^^^^^^
        def visit_call_or_write_node(node)
          if op_asgn?(node)
            s(node, op_asgn_type(node, :op_asgn), visit(node.receiver), visit_write_value(node.value), node.read_name, :"||")
          else
            s(node, op_asgn_type(node, :op_asgn2), visit(node.receiver), node.write_name, :"||", visit_write_value(node.value))
          end
        end

        # Call nodes with operators following them will either be op_asgn or
        # op_asgn2 nodes. That is determined by their call operator and their
        # right-hand side.
        private def op_asgn?(node)
          node.call_operator == "::" || (node.value.is_a?(CallNode) && node.value.opening_loc.nil? && !node.value.arguments.nil?)
        end

        # Call nodes with operators following them can use &. as an operator,
        # which changes their type by prefixing "safe_".
        private def op_asgn_type(node, type)
          node.safe_navigation? ? :"safe_#{type}" : type
        end

        # foo.bar, = 1
        # ^^^^^^^
        def visit_call_target_node(node)
          s(node, :attrasgn, visit(node.receiver), node.name)
        end

        # foo => bar => baz
        #        ^^^^^^^^^^
        def visit_capture_pattern_node(node)
          visit(node.target) << visit(node.value)
        end

        # case foo; when bar; end
        # ^^^^^^^^^^^^^^^^^^^^^^^
        def visit_case_node(node)
          s(node, :case, visit(node.predicate)).concat(visit_all(node.conditions)) << visit(node.else_clause)
        end

        # case foo; in bar; end
        # ^^^^^^^^^^^^^^^^^^^^^
        def visit_case_match_node(node)
          s(node, :case, visit(node.predicate)).concat(visit_all(node.conditions)) << visit(node.else_clause)
        end

        # class Foo; end
        # ^^^^^^^^^^^^^^
        def visit_class_node(node)
          name =
            if node.constant_path.is_a?(ConstantReadNode)
              node.name
            else
              visit(node.constant_path)
            end

          if node.body.nil?
            s(node, :class, name, visit(node.superclass))
          elsif node.body.is_a?(StatementsNode)
            compiler = copy_compiler(in_def: false)
            s(node, :class, name, visit(node.superclass)).concat(node.body.body.map { |child| child.accept(compiler) })
          else
            s(node, :class, name, visit(node.superclass), node.body.accept(copy_compiler(in_def: false)))
          end
        end

        # @@foo
        # ^^^^^
        def visit_class_variable_read_node(node)
          s(node, :cvar, node.name)
        end

        # @@foo = 1
        # ^^^^^^^^^
        #
        # @@foo, @@bar = 1
        # ^^^^^  ^^^^^
        def visit_class_variable_write_node(node)
          s(node, class_variable_write_type, node.name, visit_write_value(node.value))
        end

        # @@foo += bar
        # ^^^^^^^^^^^^
        def visit_class_variable_operator_write_node(node)
          s(node, class_variable_write_type, node.name, s(node, :call, s(node, :cvar, node.name), node.binary_operator, visit_write_value(node.value)))
        end

        # @@foo &&= bar
        # ^^^^^^^^^^^^^
        def visit_class_variable_and_write_node(node)
          s(node, :op_asgn_and, s(node, :cvar, node.name), s(node, class_variable_write_type, node.name, visit_write_value(node.value)))
        end

        # @@foo ||= bar
        # ^^^^^^^^^^^^^
        def visit_class_variable_or_write_node(node)
          s(node, :op_asgn_or, s(node, :cvar, node.name), s(node, class_variable_write_type, node.name, visit_write_value(node.value)))
        end

        # @@foo, = bar
        # ^^^^^
        def visit_class_variable_target_node(node)
          s(node, class_variable_write_type, node.name)
        end

        # If a class variable is written within a method definition, it has a
        # different type than everywhere else.
        private def class_variable_write_type
          in_def ? :cvasgn : :cvdecl
        end

        # Foo
        # ^^^
        def visit_constant_read_node(node)
          s(node, :const, node.name)
        end

        # Foo = 1
        # ^^^^^^^
        #
        # Foo, Bar = 1
        # ^^^  ^^^
        def visit_constant_write_node(node)
          s(node, :cdecl, node.name, visit_write_value(node.value))
        end

        # Foo += bar
        # ^^^^^^^^^^^
        def visit_constant_operator_write_node(node)
          s(node, :cdecl, node.name, s(node, :call, s(node, :const, node.name), node.binary_operator, visit_write_value(node.value)))
        end

        # Foo &&= bar
        # ^^^^^^^^^^^^
        def visit_constant_and_write_node(node)
          s(node, :op_asgn_and, s(node, :const, node.name), s(node, :cdecl, node.name, visit(node.value)))
        end

        # Foo ||= bar
        # ^^^^^^^^^^^^
        def visit_constant_or_write_node(node)
          s(node, :op_asgn_or, s(node, :const, node.name), s(node, :cdecl, node.name, visit(node.value)))
        end

        # Foo, = bar
        # ^^^
        def visit_constant_target_node(node)
          s(node, :cdecl, node.name)
        end

        # Foo::Bar
        # ^^^^^^^^
        def visit_constant_path_node(node)
          if node.parent.nil?
            s(node, :colon3, node.name)
          else
            s(node, :colon2, visit(node.parent), node.name)
          end
        end

        # Foo::Bar = 1
        # ^^^^^^^^^^^^
        #
        # Foo::Foo, Bar::Bar = 1
        # ^^^^^^^^  ^^^^^^^^
        def visit_constant_path_write_node(node)
          s(node, :cdecl, visit(node.target), visit_write_value(node.value))
        end

        # Foo::Bar += baz
        # ^^^^^^^^^^^^^^^
        def visit_constant_path_operator_write_node(node)
          s(node, :op_asgn, visit(node.target), node.binary_operator, visit_write_value(node.value))
        end

        # Foo::Bar &&= baz
        # ^^^^^^^^^^^^^^^^
        def visit_constant_path_and_write_node(node)
          s(node, :op_asgn_and, visit(node.target), visit_write_value(node.value))
        end

        # Foo::Bar ||= baz
        # ^^^^^^^^^^^^^^^^
        def visit_constant_path_or_write_node(node)
          s(node, :op_asgn_or, visit(node.target), visit_write_value(node.value))
        end

        # Foo::Bar, = baz
        # ^^^^^^^^
        def visit_constant_path_target_node(node)
          inner =
            if node.parent.nil?
              s(node, :colon3, node.name)
            else
              s(node, :colon2, visit(node.parent), node.name)
            end

          s(node, :const, inner)
        end

        # def foo; end
        # ^^^^^^^^^^^^
        #
        # def self.foo; end
        # ^^^^^^^^^^^^^^^^^
        def visit_def_node(node)
          name = node.name_loc.slice.to_sym
          result =
            if node.receiver.nil?
              s(node, :defn, name)
            else
              s(node, :defs, visit(node.receiver), name)
            end

          result.line(node.name_loc.start_line)
          if node.parameters.nil?
            result << s(node, :args).line(node.name_loc.start_line)
          else
            result << visit(node.parameters)
          end

          if node.body.nil?
            result << s(node, :nil)
          elsif node.body.is_a?(StatementsNode)
            compiler = copy_compiler(in_def: true)
            result.concat(node.body.body.map { |child| child.accept(compiler) })
          else
            result << node.body.accept(copy_compiler(in_def: true))
          end
        end

        # defined? a
        # ^^^^^^^^^^
        #
        # defined?(a)
        # ^^^^^^^^^^^
        def visit_defined_node(node)
          s(node, :defined, visit(node.value))
        end

        # if foo then bar else baz end
        #                 ^^^^^^^^^^^^
        def visit_else_node(node)
          visit(node.statements)
        end

        # "foo #{bar}"
        #      ^^^^^^
        def visit_embedded_statements_node(node)
          result = s(node, :evstr)
          result << visit(node.statements) unless node.statements.nil?
          result
        end

        # "foo #@bar"
        #      ^^^^^
        def visit_embedded_variable_node(node)
          s(node, :evstr, visit(node.variable))
        end

        # begin; foo; ensure; bar; end
        #             ^^^^^^^^^^^^
        def visit_ensure_node(node)
          node.statements.nil? ? s(node, :nil) : visit(node.statements)
        end

        # false
        # ^^^^^
        def visit_false_node(node)
          s(node, :false)
        end

        # foo => [*, bar, *]
        #        ^^^^^^^^^^^
        def visit_find_pattern_node(node)
          s(node, :find_pat, visit_pattern_constant(node.constant), :"*#{node.left.expression&.name}", *visit_all(node.requireds), :"*#{node.right.expression&.name}")
        end

        # if foo .. bar; end
        #    ^^^^^^^^^^
        def visit_flip_flop_node(node)
          if node.left.is_a?(IntegerNode) && node.right.is_a?(IntegerNode)
            s(node, :lit, Range.new(node.left.value, node.right.value, node.exclude_end?))
          else
            s(node, node.exclude_end? ? :flip3 : :flip2, visit(node.left), visit(node.right))
          end
        end

        # 1.0
        # ^^^
        def visit_float_node(node)
          s(node, :lit, node.value)
        end

        # for foo in bar do end
        # ^^^^^^^^^^^^^^^^^^^^^
        def visit_for_node(node)
          s(node, :for, visit(node.collection), visit(node.index), visit(node.statements))
        end

        # def foo(...); bar(...); end
        #                   ^^^
        def visit_forwarding_arguments_node(node)
          s(node, :forward_args)
        end

        # def foo(...); end
        #         ^^^
        def visit_forwarding_parameter_node(node)
          s(node, :forward_args)
        end

        # super
        # ^^^^^
        #
        # super {}
        # ^^^^^^^^
        def visit_forwarding_super_node(node)
          visit_block(node, s(node, :zsuper), node.block)
        end

        # $foo
        # ^^^^
        def visit_global_variable_read_node(node)
          s(node, :gvar, node.name)
        end

        # $foo = 1
        # ^^^^^^^^
        #
        # $foo, $bar = 1
        # ^^^^  ^^^^
        def visit_global_variable_write_node(node)
          s(node, :gasgn, node.name, visit_write_value(node.value))
        end

        # $foo += bar
        # ^^^^^^^^^^^
        def visit_global_variable_operator_write_node(node)
          s(node, :gasgn, node.name, s(node, :call, s(node, :gvar, node.name), node.binary_operator, visit(node.value)))
        end

        # $foo &&= bar
        # ^^^^^^^^^^^^
        def visit_global_variable_and_write_node(node)
          s(node, :op_asgn_and, s(node, :gvar, node.name), s(node, :gasgn, node.name, visit_write_value(node.value)))
        end

        # $foo ||= bar
        # ^^^^^^^^^^^^
        def visit_global_variable_or_write_node(node)
          s(node, :op_asgn_or, s(node, :gvar, node.name), s(node, :gasgn, node.name, visit_write_value(node.value)))
        end

        # $foo, = bar
        # ^^^^
        def visit_global_variable_target_node(node)
          s(node, :gasgn, node.name)
        end

        # {}
        # ^^
        def visit_hash_node(node)
          s(node, :hash).concat(node.elements.flat_map { |element| visit(element) })
        end

        # foo => {}
        #        ^^
        def visit_hash_pattern_node(node)
          result = s(node, :hash_pat, visit_pattern_constant(node.constant)).concat(node.elements.flat_map { |element| visit(element) })

          case node.rest
          when AssocSplatNode
            result << s(node.rest, :kwrest, :"**#{node.rest.value&.name}")
          when NoKeywordsParameterNode
            result << visit(node.rest)
          end

          result
        end

        # if foo then bar end
        # ^^^^^^^^^^^^^^^^^^^
        #
        # bar if foo
        # ^^^^^^^^^^
        #
        # foo ? bar : baz
        # ^^^^^^^^^^^^^^^
        def visit_if_node(node)
          s(node, :if, visit(node.predicate), visit(node.statements), visit(node.subsequent))
        end

        # 1i
        def visit_imaginary_node(node)
          s(node, :lit, node.value)
        end

        # { foo: }
        #   ^^^^
        def visit_implicit_node(node)
        end

        # foo { |bar,| }
        #           ^
        def visit_implicit_rest_node(node)
        end

        # case foo; in bar; end
        # ^^^^^^^^^^^^^^^^^^^^^
        def visit_in_node(node)
          pattern =
            if node.pattern.is_a?(ConstantPathNode)
              s(node.pattern, :const, visit(node.pattern))
            else
              node.pattern.accept(copy_compiler(in_pattern: true))
            end

          s(node, :in, pattern).concat(node.statements.nil? ? [nil] : visit_all(node.statements.body))
        end

        # foo[bar] += baz
        # ^^^^^^^^^^^^^^^
        def visit_index_operator_write_node(node)
          arglist = nil

          if !node.arguments.nil? || !node.block.nil?
            arglist = s(node, :arglist).concat(visit_all(node.arguments&.arguments || []))
            arglist << visit(node.block) if !node.block.nil?
          end

          s(node, :op_asgn1, visit(node.receiver), arglist, node.binary_operator, visit_write_value(node.value))
        end

        # foo[bar] &&= baz
        # ^^^^^^^^^^^^^^^^
        def visit_index_and_write_node(node)
          arglist = nil

          if !node.arguments.nil? || !node.block.nil?
            arglist = s(node, :arglist).concat(visit_all(node.arguments&.arguments || []))
            arglist << visit(node.block) if !node.block.nil?
          end

          s(node, :op_asgn1, visit(node.receiver), arglist, :"&&", visit_write_value(node.value))
        end

        # foo[bar] ||= baz
        # ^^^^^^^^^^^^^^^^
        def visit_index_or_write_node(node)
          arglist = nil

          if !node.arguments.nil? || !node.block.nil?
            arglist = s(node, :arglist).concat(visit_all(node.arguments&.arguments || []))
            arglist << visit(node.block) if !node.block.nil?
          end

          s(node, :op_asgn1, visit(node.receiver), arglist, :"||", visit_write_value(node.value))
        end

        # foo[bar], = 1
        # ^^^^^^^^
        def visit_index_target_node(node)
          arguments = visit_all(node.arguments&.arguments || [])
          arguments << visit(node.block) unless node.block.nil?

          s(node, :attrasgn, visit(node.receiver), :[]=).concat(arguments)
        end

        # @foo
        # ^^^^
        def visit_instance_variable_read_node(node)
          s(node, :ivar, node.name)
        end

        # @foo = 1
        # ^^^^^^^^
        #
        # @foo, @bar = 1
        # ^^^^  ^^^^
        def visit_instance_variable_write_node(node)
          s(node, :iasgn, node.name, visit_write_value(node.value))
        end

        # @foo += bar
        # ^^^^^^^^^^^
        def visit_instance_variable_operator_write_node(node)
          s(node, :iasgn, node.name, s(node, :call, s(node, :ivar, node.name), node.binary_operator, visit_write_value(node.value)))
        end

        # @foo &&= bar
        # ^^^^^^^^^^^^
        def visit_instance_variable_and_write_node(node)
          s(node, :op_asgn_and, s(node, :ivar, node.name), s(node, :iasgn, node.name, visit(node.value)))
        end

        # @foo ||= bar
        # ^^^^^^^^^^^^
        def visit_instance_variable_or_write_node(node)
          s(node, :op_asgn_or, s(node, :ivar, node.name), s(node, :iasgn, node.name, visit(node.value)))
        end

        # @foo, = bar
        # ^^^^
        def visit_instance_variable_target_node(node)
          s(node, :iasgn, node.name)
        end

        # 1
        # ^
        def visit_integer_node(node)
          s(node, :lit, node.value)
        end

        # if /foo #{bar}/ then end
        #    ^^^^^^^^^^^^
        def visit_interpolated_match_last_line_node(node)
          parts = visit_interpolated_parts(node.parts)
          regexp =
            if parts.length == 1
              s(node, :lit, Regexp.new(parts.first, node.options))
            else
              s(node, :dregx).concat(parts).tap do |result|
                options = node.options
                result << options if options != 0
              end
            end

          s(node, :match, regexp)
        end

        # /foo #{bar}/
        # ^^^^^^^^^^^^
        def visit_interpolated_regular_expression_node(node)
          parts = visit_interpolated_parts(node.parts)

          if parts.length == 1
            s(node, :lit, Regexp.new(parts.first, node.options))
          else
            s(node, :dregx).concat(parts).tap do |result|
              options = node.options
              result << options if options != 0
            end
          end
        end

        # "foo #{bar}"
        # ^^^^^^^^^^^^
        def visit_interpolated_string_node(node)
          parts = visit_interpolated_parts(node.parts)
          parts.length == 1 ? s(node, :str, parts.first) : s(node, :dstr).concat(parts)
        end

        # :"foo #{bar}"
        # ^^^^^^^^^^^^^
        def visit_interpolated_symbol_node(node)
          parts = visit_interpolated_parts(node.parts)
          parts.length == 1 ? s(node, :lit, parts.first.to_sym) : s(node, :dsym).concat(parts)
        end

        # `foo #{bar}`
        # ^^^^^^^^^^^^
        def visit_interpolated_x_string_node(node)
          source = node.heredoc? ? node.parts.first : node
          parts = visit_interpolated_parts(node.parts)
          parts.length == 1 ? s(source, :xstr, parts.first) : s(source, :dxstr).concat(parts)
        end

        # Visit the interpolated content of the string-like node.
        private def visit_interpolated_parts(parts)
          visited = []

          parts.each do |part|
            result = visit(part)

            if result[0] == :evstr && result[1]
              if result[1][0] == :str
                visited << result[1]
              elsif result[1][0] == :dstr
                visited.concat(result[1][1..-1])
              else
                visited << result
              end
              visited << :space
            elsif result[0] == :dstr
              if !visited.empty? && part.parts[0].is_a?(StringNode)
                # If we are in the middle of an implicitly concatenated string,
                # we should not have a bare string as the first part. In this
                # case we need to visit just that first part and then we can
                # push the rest of the parts onto the visited array.
                result[1] = visit(part.parts[0])
              end
              visited.concat(result[1..-1])
            else
              visited << result
            end
          end

          state = :beginning #: :beginning | :string_content | :interpolated_content
          results = []

          visited.each_with_index do |result, index|
            case state
            when :beginning
              if result.is_a?(String)
                results << result
                state = :string_content
              elsif result.is_a?(Array) && result[0] == :str
                results << result[1]
                state = :string_content
              else
                results << ""
                results << result
                state = :interpolated_content
              end
            when :string_content
              if result == :space
                # continue
              elsif result.is_a?(String)
                results[0] = "#{results[0]}#{result}"
              elsif result.is_a?(Array) && result[0] == :str
                results[0] = "#{results[0]}#{result[1]}"
              else
                results << result
                state = :interpolated_content
              end
            when :interpolated_content
              if result == :space
                # continue
              elsif visited[index - 1] != :space && result.is_a?(Array) && result[0] == :str && results[-1][0] == :str && (results[-1].line_max == result.line)
                results[-1][1] = "#{results[-1][1]}#{result[1]}"
                results[-1].line_max = result.line_max
              else
                results << result
              end
            end
          end

          results
        end

        # -> { it }
        #      ^^
        def visit_it_local_variable_read_node(node)
          s(node, :call, nil, :it)
        end

        # foo(bar: baz)
        #     ^^^^^^^^
        def visit_keyword_hash_node(node)
          s(node, :hash).concat(node.elements.flat_map { |element| visit(element) })
        end

        # def foo(**bar); end
        #         ^^^^^
        #
        # def foo(**); end
        #         ^^
        def visit_keyword_rest_parameter_node(node)
          :"**#{node.name}"
        end

        # -> {}
        def visit_lambda_node(node)
          parameters =
            case node.parameters
            when nil, NumberedParametersNode
              s(node, :args)
            else
              visit(node.parameters)
            end

          if node.body.nil?
            s(node, :iter, s(node, :lambda), parameters)
          else
            s(node, :iter, s(node, :lambda), parameters, visit(node.body))
          end
        end

        # foo
        # ^^^
        def visit_local_variable_read_node(node)
          if node.name.match?(/^_\d$/)
            s(node, :call, nil, node.name)
          else
            s(node, :lvar, node.name)
          end
        end

        # foo = 1
        # ^^^^^^^
        #
        # foo, bar = 1
        # ^^^  ^^^
        def visit_local_variable_write_node(node)
          s(node, :lasgn, node.name, visit_write_value(node.value))
        end

        # foo += bar
        # ^^^^^^^^^^
        def visit_local_variable_operator_write_node(node)
          s(node, :lasgn, node.name, s(node, :call, s(node, :lvar, node.name), node.binary_operator, visit_write_value(node.value)))
        end

        # foo &&= bar
        # ^^^^^^^^^^^
        def visit_local_variable_and_write_node(node)
          s(node, :op_asgn_and, s(node, :lvar, node.name), s(node, :lasgn, node.name, visit_write_value(node.value)))
        end

        # foo ||= bar
        # ^^^^^^^^^^^
        def visit_local_variable_or_write_node(node)
          s(node, :op_asgn_or, s(node, :lvar, node.name), s(node, :lasgn, node.name, visit_write_value(node.value)))
        end

        # foo, = bar
        # ^^^
        def visit_local_variable_target_node(node)
          s(node, :lasgn, node.name)
        end

        # if /foo/ then end
        #    ^^^^^
        def visit_match_last_line_node(node)
          s(node, :match, s(node, :lit, Regexp.new(node.unescaped, node.options)))
        end

        # foo in bar
        # ^^^^^^^^^^
        def visit_match_predicate_node(node)
          s(node, :case, visit(node.value), s(node, :in, node.pattern.accept(copy_compiler(in_pattern: true)), nil), nil)
        end

        # foo => bar
        # ^^^^^^^^^^
        def visit_match_required_node(node)
          s(node, :case, visit(node.value), s(node, :in, node.pattern.accept(copy_compiler(in_pattern: true)), nil), nil)
        end

        # /(?<foo>foo)/ =~ bar
        # ^^^^^^^^^^^^^^^^^^^^
        def visit_match_write_node(node)
          s(node, :match2, visit(node.call.receiver), visit(node.call.arguments.arguments.first))
        end

        # A node that is missing from the syntax tree. This is only used in the
        # case of a syntax error. The parser gem doesn't have such a concept, so
        # we invent our own here.
        def visit_missing_node(node)
          raise "Cannot visit missing node directly"
        end

        # module Foo; end
        # ^^^^^^^^^^^^^^^
        def visit_module_node(node)
          name =
            if node.constant_path.is_a?(ConstantReadNode)
              node.name
            else
              visit(node.constant_path)
            end

          if node.body.nil?
            s(node, :module, name)
          elsif node.body.is_a?(StatementsNode)
            compiler = copy_compiler(in_def: false)
            s(node, :module, name).concat(node.body.body.map { |child| child.accept(compiler) })
          else
            s(node, :module, name, node.body.accept(copy_compiler(in_def: false)))
          end
        end

        # foo, bar = baz
        # ^^^^^^^^
        def visit_multi_target_node(node)
          targets = [*node.lefts]
          targets << node.rest if !node.rest.nil? && !node.rest.is_a?(ImplicitRestNode)
          targets.concat(node.rights)

          s(node, :masgn, s(node, :array).concat(visit_all(targets)))
        end

        # foo, bar = baz
        # ^^^^^^^^^^^^^^
        def visit_multi_write_node(node)
          targets = [*node.lefts]
          targets << node.rest if !node.rest.nil? && !node.rest.is_a?(ImplicitRestNode)
          targets.concat(node.rights)

          value =
            if node.value.is_a?(ArrayNode) && node.value.opening_loc.nil?
              if node.value.elements.length == 1 && node.value.elements.first.is_a?(SplatNode)
                visit(node.value.elements.first)
              else
                visit(node.value)
              end
            else
              s(node.value, :to_ary, visit(node.value))
            end

          s(node, :masgn, s(node, :array).concat(visit_all(targets)), value)
        end

        # next
        # ^^^^
        #
        # next foo
        # ^^^^^^^^
        def visit_next_node(node)
          if node.arguments.nil?
            s(node, :next)
          elsif node.arguments.arguments.length == 1
            argument = node.arguments.arguments.first
            s(node, :next, argument.is_a?(SplatNode) ? s(node, :svalue, visit(argument)) : visit(argument))
          else
            s(node, :next, s(node, :array).concat(visit_all(node.arguments.arguments)))
          end
        end

        # nil
        # ^^^
        def visit_nil_node(node)
          s(node, :nil)
        end

        # def foo(**nil); end
        #         ^^^^^
        def visit_no_keywords_parameter_node(node)
          in_pattern ? s(node, :kwrest, :"**nil") : :"**nil"
        end

        # -> { _1 + _2 }
        # ^^^^^^^^^^^^^^
        def visit_numbered_parameters_node(node)
          raise "Cannot visit numbered parameters directly"
        end

        # $1
        # ^^
        def visit_numbered_reference_read_node(node)
          s(node, :nth_ref, node.number)
        end

        # def foo(bar: baz); end
        #         ^^^^^^^^
        def visit_optional_keyword_parameter_node(node)
          s(node, :kwarg, node.name, visit(node.value))
        end

        # def foo(bar = 1); end
        #         ^^^^^^^
        def visit_optional_parameter_node(node)
          s(node, :lasgn, node.name, visit(node.value))
        end

        # a or b
        # ^^^^^^
        def visit_or_node(node)
          left = visit(node.left)

          if left[0] == :or
            # ruby_parser has the or keyword as right-associative as opposed to
            # prism which has it as left-associative. We reverse that
            # associativity here.
            nest = left
            nest = nest[2] while nest[2][0] == :or
            nest[2] = s(node, :or, nest[2], visit(node.right))
            left
          else
            s(node, :or, left, visit(node.right))
          end
        end

        # def foo(bar, *baz); end
        #         ^^^^^^^^^
        def visit_parameters_node(node)
          children =
            node.compact_child_nodes.map do |element|
              if element.is_a?(MultiTargetNode)
                visit_destructured_parameter(element)
              else
                visit(element)
              end
            end

          s(node, :args).concat(children)
        end

        # def foo((bar, baz)); end
        #         ^^^^^^^^^^
        private def visit_destructured_parameter(node)
          children =
            [*node.lefts, *node.rest, *node.rights].map do |child|
              case child
              when RequiredParameterNode
                visit(child)
              when MultiTargetNode
                visit_destructured_parameter(child)
              when SplatNode
                :"*#{child.expression&.name}"
              else
                raise
              end
            end

          s(node, :masgn).concat(children)
        end

        # ()
        # ^^
        #
        # (1)
        # ^^^
        def visit_parentheses_node(node)
          if node.body.nil?
            s(node, :nil)
          else
            visit(node.body)
          end
        end

        # foo => ^(bar)
        #        ^^^^^^
        def visit_pinned_expression_node(node)
          node.expression.accept(copy_compiler(in_pattern: false))
        end

        # foo = 1 and bar => ^foo
        #                    ^^^^
        def visit_pinned_variable_node(node)
          if node.variable.is_a?(LocalVariableReadNode) && node.variable.name.match?(/^_\d$/)
            s(node, :lvar, node.variable.name)
          else
            visit(node.variable)
          end
        end

        # END {}
        def visit_post_execution_node(node)
          s(node, :iter, s(node, :postexe), 0, visit(node.statements))
        end

        # BEGIN {}
        def visit_pre_execution_node(node)
          s(node, :iter, s(node, :preexe), 0, visit(node.statements))
        end

        # The top-level program node.
        def visit_program_node(node)
          visit(node.statements)
        end

        # 0..5
        # ^^^^
        def visit_range_node(node)
          if !in_pattern && !node.left.nil? && !node.right.nil? && ([node.left.type, node.right.type] - %i[nil_node integer_node]).empty?
            left = node.left.value if node.left.is_a?(IntegerNode)
            right = node.right.value if node.right.is_a?(IntegerNode)
            s(node, :lit, Range.new(left, right, node.exclude_end?))
          else
            s(node, node.exclude_end? ? :dot3 : :dot2, visit_range_bounds_node(node.left), visit_range_bounds_node(node.right))
          end
        end

        # If the bounds of a range node are empty parentheses, then they do not
        # get replaced by their usual s(:nil), but instead are s(:begin).
        private def visit_range_bounds_node(node)
          if node.is_a?(ParenthesesNode) && node.body.nil?
            s(node, :begin)
          else
            visit(node)
          end
        end

        # 1r
        # ^^
        def visit_rational_node(node)
          s(node, :lit, node.value)
        end

        # redo
        # ^^^^
        def visit_redo_node(node)
          s(node, :redo)
        end

        # /foo/
        # ^^^^^
        def visit_regular_expression_node(node)
          s(node, :lit, Regexp.new(node.unescaped, node.options))
        end

        # def foo(bar:); end
        #         ^^^^
        def visit_required_keyword_parameter_node(node)
          s(node, :kwarg, node.name)
        end

        # def foo(bar); end
        #         ^^^
        def visit_required_parameter_node(node)
          node.name
        end

        # foo rescue bar
        # ^^^^^^^^^^^^^^
        def visit_rescue_modifier_node(node)
          s(node, :rescue, visit(node.expression), s(node.rescue_expression, :resbody, s(node.rescue_expression, :array), visit(node.rescue_expression)))
        end

        # begin; rescue; end
        #        ^^^^^^^
        def visit_rescue_node(node)
          exceptions =
            if node.exceptions.length == 1 && node.exceptions.first.is_a?(SplatNode)
              visit(node.exceptions.first)
            else
              s(node, :array).concat(visit_all(node.exceptions))
            end

          if !node.reference.nil?
            exceptions << (visit(node.reference) << s(node.reference, :gvar, :"$!"))
          end

          s(node, :resbody, exceptions).concat(node.statements.nil? ? [nil] : visit_all(node.statements.body))
        end

        # def foo(*bar); end
        #         ^^^^
        #
        # def foo(*); end
        #         ^
        def visit_rest_parameter_node(node)
          :"*#{node.name}"
        end

        # retry
        # ^^^^^
        def visit_retry_node(node)
          s(node, :retry)
        end

        # return
        # ^^^^^^
        #
        # return 1
        # ^^^^^^^^
        def visit_return_node(node)
          if node.arguments.nil?
            s(node, :return)
          elsif node.arguments.arguments.length == 1
            argument = node.arguments.arguments.first
            s(node, :return, argument.is_a?(SplatNode) ? s(node, :svalue, visit(argument)) : visit(argument))
          else
            s(node, :return, s(node, :array).concat(visit_all(node.arguments.arguments)))
          end
        end

        # self
        # ^^^^
        def visit_self_node(node)
          s(node, :self)
        end

        # A shareable constant.
        def visit_shareable_constant_node(node)
          visit(node.write)
        end

        # class << self; end
        # ^^^^^^^^^^^^^^^^^^
        def visit_singleton_class_node(node)
          s(node, :sclass, visit(node.expression)).tap do |sexp|
            sexp << node.body.accept(copy_compiler(in_def: false)) unless node.body.nil?
          end
        end

        # __ENCODING__
        # ^^^^^^^^^^^^
        def visit_source_encoding_node(node)
          # TODO
          s(node, :colon2, s(node, :const, :Encoding), :UTF_8)
        end

        # __FILE__
        # ^^^^^^^^
        def visit_source_file_node(node)
          s(node, :str, node.filepath)
        end

        # __LINE__
        # ^^^^^^^^
        def visit_source_line_node(node)
          s(node, :lit, node.location.start_line)
        end

        # foo(*bar)
        #     ^^^^
        #
        # def foo((bar, *baz)); end
        #               ^^^^
        #
        # def foo(*); bar(*); end
        #                 ^
        def visit_splat_node(node)
          if node.expression.nil?
            s(node, :splat)
          else
            s(node, :splat, visit(node.expression))
          end
        end

        # A list of statements.
        def visit_statements_node(node)
          first, *rest = node.body

          if rest.empty?
            visit(first)
          else
            s(node, :block).concat(visit_all(node.body))
          end
        end

        # "foo"
        # ^^^^^
        def visit_string_node(node)
          unescaped = node.unescaped

          if node.forced_binary_encoding?
            unescaped = unescaped.dup
            unescaped.force_encoding(Encoding::BINARY)
          end

          s(node, :str, unescaped)
        end

        # super(foo)
        # ^^^^^^^^^^
        def visit_super_node(node)
          arguments = node.arguments&.arguments || []
          block = node.block

          if block.is_a?(BlockArgumentNode)
            arguments << block
            block = nil
          end

          visit_block(node, s(node, :super).concat(visit_all(arguments)), block)
        end

        # :foo
        # ^^^^
        def visit_symbol_node(node)
          node.value == "!@" ? s(node, :lit, :"!@") : s(node, :lit, node.unescaped.to_sym)
        end

        # true
        # ^^^^
        def visit_true_node(node)
          s(node, :true)
        end

        # undef foo
        # ^^^^^^^^^
        def visit_undef_node(node)
          names = node.names.map { |name| s(node, :undef, visit(name)) }
          names.length == 1 ? names.first : s(node, :block).concat(names)
        end

        # unless foo; bar end
        # ^^^^^^^^^^^^^^^^^^^
        #
        # bar unless foo
        # ^^^^^^^^^^^^^^
        def visit_unless_node(node)
          s(node, :if, visit(node.predicate), visit(node.else_clause), visit(node.statements))
        end

        # until foo; bar end
        # ^^^^^^^^^^^^^^^^^
        #
        # bar until foo
        # ^^^^^^^^^^^^^
        def visit_until_node(node)
          s(node, :until, visit(node.predicate), visit(node.statements), !node.begin_modifier?)
        end

        # case foo; when bar; end
        #           ^^^^^^^^^^^^^
        def visit_when_node(node)
          s(node, :when, s(node, :array).concat(visit_all(node.conditions))).concat(node.statements.nil? ? [nil] : visit_all(node.statements.body))
        end

        # while foo; bar end
        # ^^^^^^^^^^^^^^^^^^
        #
        # bar while foo
        # ^^^^^^^^^^^^^
        def visit_while_node(node)
          s(node, :while, visit(node.predicate), visit(node.statements), !node.begin_modifier?)
        end

        # `foo`
        # ^^^^^
        def visit_x_string_node(node)
          result = s(node, :xstr, node.unescaped)

          if node.heredoc?
            result.line = node.content_loc.start_line
            result.line_max = node.content_loc.end_line
          end

          result
        end

        # yield
        # ^^^^^
        #
        # yield 1
        # ^^^^^^^
        def visit_yield_node(node)
          s(node, :yield).concat(visit_all(node.arguments&.arguments || []))
        end

        private

        # Create a new compiler with the given options.
        def copy_compiler(in_def: self.in_def, in_pattern: self.in_pattern)
          Compiler.new(file, in_def: in_def, in_pattern: in_pattern)
        end

        # Create a new Sexp object from the given prism node and arguments.
        def s(node, *arguments)
          result = Sexp.new(*arguments)
          result.file = file
          result.line = node.location.start_line
          result.line_max = node.location.end_line
          result
        end

        # Visit a block node, which will modify the AST by wrapping the given
        # visited node in an iter node.
        def visit_block(node, sexp, block)
          if block.nil?
            sexp
          else
            parameters =
              case block.parameters
              when nil, ItParametersNode, NumberedParametersNode
                0
              else
                visit(block.parameters)
              end

            if block.body.nil?
              s(node, :iter, sexp, parameters)
            else
              s(node, :iter, sexp, parameters, visit(block.body))
            end
          end
        end

        # Pattern constants get wrapped in another layer of :const.
        def visit_pattern_constant(node)
          case node
          when nil
            # nothing
          when ConstantReadNode
            visit(node)
          else
            s(node, :const, visit(node))
          end
        end

        # Visit the value of a write, which will be on the right-hand side of
        # a write operator. Because implicit arrays can have splats, those could
        # potentially be wrapped in an svalue node.
        def visit_write_value(node)
          if node.is_a?(ArrayNode) && node.opening_loc.nil?
            if node.elements.length == 1 && node.elements.first.is_a?(SplatNode)
              s(node, :svalue, visit(node.elements.first))
            else
              s(node, :svalue, visit(node))
            end
          else
            visit(node)
          end
        end
      end

      private_constant :Compiler

      # Parse the given source and translate it into the seattlerb/ruby_parser
      # gem's Sexp format.
      def parse(source, filepath = "(string)")
        translate(Prism.parse(source, filepath: filepath, partial_script: true), filepath)
      end

      # Parse the given file and translate it into the seattlerb/ruby_parser
      # gem's Sexp format.
      def parse_file(filepath)
        translate(Prism.parse_file(filepath, partial_script: true), filepath)
      end

      class << self
        # Parse the given source and translate it into the seattlerb/ruby_parser
        # gem's Sexp format.
        def parse(source, filepath = "(string)")
          new.parse(source, filepath)
        end

        # Parse the given file and translate it into the seattlerb/ruby_parser
        # gem's Sexp format.
        def parse_file(filepath)
          new.parse_file(filepath)
        end
      end

      private

      # Translate the given parse result and filepath into the
      # seattlerb/ruby_parser gem's Sexp format.
      def translate(result, filepath)
        if result.failure?
          error = result.errors.first
          raise ::RubyParser::SyntaxError, "#{filepath}:#{error.location.start_line} :: #{error.message}"
        end

        result.value.accept(Compiler.new(filepath))
      end
    end
  end
end
