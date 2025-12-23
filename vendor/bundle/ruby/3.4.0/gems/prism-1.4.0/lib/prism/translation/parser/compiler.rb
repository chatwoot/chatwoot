# frozen_string_literal: true

module Prism
  module Translation
    class Parser
      # A visitor that knows how to convert a prism syntax tree into the
      # whitequark/parser gem's syntax tree.
      class Compiler < ::Prism::Compiler
        # Raised when the tree is malformed or there is a bug in the compiler.
        class CompilationError < StandardError
        end

        # The Parser::Base instance that is being used to build the AST.
        attr_reader :parser

        # The Parser::Builders::Default instance that is being used to build the
        # AST.
        attr_reader :builder

        # The Parser::Source::Buffer instance that is holding a reference to the
        # source code.
        attr_reader :source_buffer

        # The offset cache that is used to map between byte and character
        # offsets in the file.
        attr_reader :offset_cache

        # The types of values that can be forwarded in the current scope.
        attr_reader :forwarding

        # Whether or not the current node is in a destructure.
        attr_reader :in_destructure

        # Whether or not the current node is in a pattern.
        attr_reader :in_pattern

        # Initialize a new compiler with the given parser, offset cache, and
        # options.
        def initialize(parser, offset_cache, forwarding: [], in_destructure: false, in_pattern: false)
          @parser = parser
          @builder = parser.builder
          @source_buffer = parser.source_buffer
          @offset_cache = offset_cache

          @forwarding = forwarding
          @in_destructure = in_destructure
          @in_pattern = in_pattern
        end

        # alias foo bar
        # ^^^^^^^^^^^^^
        def visit_alias_method_node(node)
          builder.alias(token(node.keyword_loc), visit(node.new_name), visit(node.old_name))
        end

        # alias $foo $bar
        # ^^^^^^^^^^^^^^^
        def visit_alias_global_variable_node(node)
          builder.alias(token(node.keyword_loc), visit(node.new_name), visit(node.old_name))
        end

        # foo => bar | baz
        #        ^^^^^^^^^
        def visit_alternation_pattern_node(node)
          builder.match_alt(visit(node.left), token(node.operator_loc), visit(node.right))
        end

        # a and b
        # ^^^^^^^
        def visit_and_node(node)
          builder.logical_op(:and, visit(node.left), token(node.operator_loc), visit(node.right))
        end

        # []
        # ^^
        def visit_array_node(node)
          if node.opening&.start_with?("%w", "%W", "%i", "%I")
            elements = node.elements.flat_map do |element|
              if element.is_a?(StringNode)
                if element.content.include?("\n")
                  string_nodes_from_line_continuations(element.unescaped, element.content, element.content_loc.start_offset, node.opening)
                else
                  [builder.string_internal([element.unescaped, srange(element.content_loc)])]
                end
              elsif element.is_a?(InterpolatedStringNode)
                builder.string_compose(
                  token(element.opening_loc),
                  string_nodes_from_interpolation(element, node.opening),
                  token(element.closing_loc)
                )
              else
                [visit(element)]
              end
            end
          else
            elements = visit_all(node.elements)
          end

          builder.array(token(node.opening_loc), elements, token(node.closing_loc))
        end

        # foo => [bar]
        #        ^^^^^
        def visit_array_pattern_node(node)
          elements = [*node.requireds]
          elements << node.rest if !node.rest.nil? && !node.rest.is_a?(ImplicitRestNode)
          elements.concat(node.posts)
          visited = visit_all(elements)

          if node.rest.is_a?(ImplicitRestNode)
            visited[-1] = builder.match_with_trailing_comma(visited[-1], token(node.rest.location))
          end

          if node.constant
            if visited.empty?
              builder.const_pattern(visit(node.constant), token(node.opening_loc), builder.array_pattern(token(node.opening_loc), visited, token(node.closing_loc)), token(node.closing_loc))
            else
              builder.const_pattern(visit(node.constant), token(node.opening_loc), builder.array_pattern(nil, visited, nil), token(node.closing_loc))
            end
          else
            builder.array_pattern(token(node.opening_loc), visited, token(node.closing_loc))
          end
        end

        # foo(bar)
        #     ^^^
        def visit_arguments_node(node)
          visit_all(node.arguments)
        end

        # { a: 1 }
        #   ^^^^
        def visit_assoc_node(node)
          key = node.key

          if in_pattern
            if node.value.is_a?(ImplicitNode)
              if key.is_a?(SymbolNode)
                if key.opening.nil?
                  builder.match_hash_var([key.unescaped, srange(key.location)])
                else
                  builder.match_hash_var_from_str(token(key.opening_loc), [builder.string_internal([key.unescaped, srange(key.value_loc)])], token(key.closing_loc))
                end
              else
                builder.match_hash_var_from_str(token(key.opening_loc), visit_all(key.parts), token(key.closing_loc))
              end
            elsif key.opening.nil?
              builder.pair_keyword([key.unescaped, srange(key.location)], visit(node.value))
            else
              builder.pair_quoted(token(key.opening_loc), [builder.string_internal([key.unescaped, srange(key.value_loc)])], token(key.closing_loc), visit(node.value))
            end
          elsif node.value.is_a?(ImplicitNode)
            value = node.value.value

            implicit_value = if value.is_a?(CallNode)
              builder.call_method(nil, nil, [value.name, srange(value.message_loc)])
            elsif value.is_a?(ConstantReadNode)
              builder.const([value.name, srange(key.value_loc)])
            else
              builder.ident([value.name, srange(key.value_loc)]).updated(:lvar)
            end

            builder.pair_keyword([key.unescaped, srange(key)], implicit_value)
          elsif node.operator_loc
            builder.pair(visit(key), token(node.operator_loc), visit(node.value))
          elsif key.is_a?(SymbolNode) && key.opening_loc.nil?
            builder.pair_keyword([key.unescaped, srange(key.location)], visit(node.value))
          else
            parts =
              if key.is_a?(SymbolNode)
                [builder.string_internal([key.unescaped, srange(key.value_loc)])]
              else
                visit_all(key.parts)
              end

            builder.pair_quoted(token(key.opening_loc), parts, token(key.closing_loc), visit(node.value))
          end
        end

        # def foo(**); bar(**); end
        #                  ^^
        #
        # { **foo }
        #   ^^^^^
        def visit_assoc_splat_node(node)
          if in_pattern
            builder.match_rest(token(node.operator_loc), token(node.value&.location))
          elsif node.value.nil? && forwarding.include?(:**)
            builder.forwarded_kwrestarg(token(node.operator_loc))
          else
            builder.kwsplat(token(node.operator_loc), visit(node.value))
          end
        end

        # $+
        # ^^
        def visit_back_reference_read_node(node)
          builder.back_ref(token(node.location))
        end

        # begin end
        # ^^^^^^^^^
        def visit_begin_node(node)
          rescue_bodies = []

          if (rescue_clause = node.rescue_clause)
            begin
              find_start_offset = (rescue_clause.reference&.location || rescue_clause.exceptions.last&.location || rescue_clause.keyword_loc).end_offset
              find_end_offset = (
                rescue_clause.statements&.location&.start_offset ||
                rescue_clause.subsequent&.location&.start_offset ||
                node.else_clause&.location&.start_offset ||
                node.ensure_clause&.location&.start_offset ||
                node.end_keyword_loc&.start_offset ||
                find_start_offset + 1
              )

              rescue_bodies << builder.rescue_body(
                token(rescue_clause.keyword_loc),
                rescue_clause.exceptions.any? ? builder.array(nil, visit_all(rescue_clause.exceptions), nil) : nil,
                token(rescue_clause.operator_loc),
                visit(rescue_clause.reference),
                srange_find(find_start_offset, find_end_offset, ";"),
                visit(rescue_clause.statements)
              )
            end until (rescue_clause = rescue_clause.subsequent).nil?
          end

          begin_body =
            builder.begin_body(
              visit(node.statements),
              rescue_bodies,
              token(node.else_clause&.else_keyword_loc),
              visit(node.else_clause),
              token(node.ensure_clause&.ensure_keyword_loc),
              visit(node.ensure_clause&.statements)
            )

          if node.begin_keyword_loc
            builder.begin_keyword(token(node.begin_keyword_loc), begin_body, token(node.end_keyword_loc))
          else
            begin_body
          end
        end

        # foo(&bar)
        #     ^^^^
        def visit_block_argument_node(node)
          builder.block_pass(token(node.operator_loc), visit(node.expression))
        end

        # foo { |; bar| }
        #          ^^^
        def visit_block_local_variable_node(node)
          builder.shadowarg(token(node.location))
        end

        # A block on a keyword or method call.
        def visit_block_node(node)
          raise CompilationError, "Cannot directly compile block nodes"
        end

        # def foo(&bar); end
        #         ^^^^
        def visit_block_parameter_node(node)
          builder.blockarg(token(node.operator_loc), token(node.name_loc))
        end

        # A block's parameters.
        def visit_block_parameters_node(node)
          [*visit(node.parameters)].concat(visit_all(node.locals))
        end

        # break
        # ^^^^^
        #
        # break foo
        # ^^^^^^^^^
        def visit_break_node(node)
          builder.keyword_cmd(:break, token(node.keyword_loc), nil, visit(node.arguments) || [], nil)
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
          name = node.name
          arguments = node.arguments&.arguments || []
          block = node.block

          if block.is_a?(BlockArgumentNode)
            arguments = [*arguments, block]
            block = nil
          end

          if node.call_operator_loc.nil?
            case name
            when :-@
              case (receiver = node.receiver).type
              when :integer_node, :float_node, :rational_node, :imaginary_node
                return visit(numeric_negate(node.message_loc, receiver))
              end
            when :!
              return visit_block(builder.not_op(token(node.message_loc), token(node.opening_loc), visit(node.receiver), token(node.closing_loc)), block)
            when :=~
              if (receiver = node.receiver).is_a?(RegularExpressionNode)
                return builder.match_op(visit(receiver), token(node.message_loc), visit(node.arguments.arguments.first))
              end
            when :[]
              return visit_block(builder.index(visit(node.receiver), token(node.opening_loc), visit_all(arguments), token(node.closing_loc)), block)
            when :[]=
              if node.message != "[]=" && node.arguments && block.nil? && !node.safe_navigation?
                arguments = node.arguments.arguments[...-1]
                arguments << node.block if node.block

                return visit_block(
                  builder.assign(
                    builder.index_asgn(
                      visit(node.receiver),
                      token(node.opening_loc),
                      visit_all(arguments),
                      token(node.closing_loc),
                    ),
                    srange_find(node.message_loc.end_offset, node.arguments.arguments.last.location.start_offset, "="),
                    visit(node.arguments.arguments.last)
                  ),
                  block
                )
              end
            end
          end

          message_loc = node.message_loc
          call_operator_loc = node.call_operator_loc
          call_operator = [{ "." => :dot, "&." => :anddot, "::" => "::" }.fetch(call_operator_loc.slice), srange(call_operator_loc)] if call_operator_loc

          visit_block(
            if name.end_with?("=") && !message_loc.slice.end_with?("=") && node.arguments && block.nil?
              builder.assign(
                builder.attr_asgn(visit(node.receiver), call_operator, token(message_loc)),
                srange_find(message_loc.end_offset, node.arguments.location.start_offset, "="),
                visit(node.arguments.arguments.last)
              )
            else
              builder.call_method(
                visit(node.receiver),
                call_operator,
                message_loc ? [node.name, srange(message_loc)] : nil,
                token(node.opening_loc),
                visit_all(arguments),
                token(node.closing_loc)
              )
            end,
            block
          )
        end

        # foo.bar += baz
        # ^^^^^^^^^^^^^^^
        def visit_call_operator_write_node(node)
          call_operator_loc = node.call_operator_loc

          builder.op_assign(
            builder.call_method(
              visit(node.receiver),
              call_operator_loc.nil? ? nil : [{ "." => :dot, "&." => :anddot, "::" => "::" }.fetch(call_operator_loc.slice), srange(call_operator_loc)],
              node.message_loc ? [node.read_name, srange(node.message_loc)] : nil,
              nil,
              [],
              nil
            ),
            [node.binary_operator_loc.slice.chomp("="), srange(node.binary_operator_loc)],
            visit(node.value)
          )
        end

        # foo.bar &&= baz
        # ^^^^^^^^^^^^^^^
        def visit_call_and_write_node(node)
          call_operator_loc = node.call_operator_loc

          builder.op_assign(
            builder.call_method(
              visit(node.receiver),
              call_operator_loc.nil? ? nil : [{ "." => :dot, "&." => :anddot, "::" => "::" }.fetch(call_operator_loc.slice), srange(call_operator_loc)],
              node.message_loc ? [node.read_name, srange(node.message_loc)] : nil,
              nil,
              [],
              nil
            ),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # foo.bar ||= baz
        # ^^^^^^^^^^^^^^^
        def visit_call_or_write_node(node)
          call_operator_loc = node.call_operator_loc

          builder.op_assign(
            builder.call_method(
              visit(node.receiver),
              call_operator_loc.nil? ? nil : [{ "." => :dot, "&." => :anddot, "::" => "::" }.fetch(call_operator_loc.slice), srange(call_operator_loc)],
              node.message_loc ? [node.read_name, srange(node.message_loc)] : nil,
              nil,
              [],
              nil
            ),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # foo.bar, = 1
        # ^^^^^^^
        def visit_call_target_node(node)
          call_operator_loc = node.call_operator_loc

          builder.attr_asgn(
            visit(node.receiver),
            call_operator_loc.nil? ? nil : [{ "." => :dot, "&." => :anddot, "::" => "::" }.fetch(call_operator_loc.slice), srange(call_operator_loc)],
            token(node.message_loc)
          )
        end

        # foo => bar => baz
        #        ^^^^^^^^^^
        def visit_capture_pattern_node(node)
          builder.match_as(visit(node.value), token(node.operator_loc), visit(node.target))
        end

        # case foo; when bar; end
        # ^^^^^^^^^^^^^^^^^^^^^^^
        def visit_case_node(node)
          builder.case(
            token(node.case_keyword_loc),
            visit(node.predicate),
            visit_all(node.conditions),
            token(node.else_clause&.else_keyword_loc),
            visit(node.else_clause),
            token(node.end_keyword_loc)
          )
        end

        # case foo; in bar; end
        # ^^^^^^^^^^^^^^^^^^^^^
        def visit_case_match_node(node)
          builder.case_match(
            token(node.case_keyword_loc),
            visit(node.predicate),
            visit_all(node.conditions),
            token(node.else_clause&.else_keyword_loc),
            visit(node.else_clause),
            token(node.end_keyword_loc)
          )
        end

        # class Foo; end
        # ^^^^^^^^^^^^^^
        def visit_class_node(node)
          builder.def_class(
            token(node.class_keyword_loc),
            visit(node.constant_path),
            token(node.inheritance_operator_loc),
            visit(node.superclass),
            node.body&.accept(copy_compiler(forwarding: [])),
            token(node.end_keyword_loc)
          )
        end

        # @@foo
        # ^^^^^
        def visit_class_variable_read_node(node)
          builder.cvar(token(node.location))
        end

        # @@foo = 1
        # ^^^^^^^^^
        def visit_class_variable_write_node(node)
          builder.assign(
            builder.assignable(builder.cvar(token(node.name_loc))),
            token(node.operator_loc),
            visit(node.value)
          )
        end

        # @@foo += bar
        # ^^^^^^^^^^^^
        def visit_class_variable_operator_write_node(node)
          builder.op_assign(
            builder.assignable(builder.cvar(token(node.name_loc))),
            [node.binary_operator_loc.slice.chomp("="), srange(node.binary_operator_loc)],
            visit(node.value)
          )
        end

        # @@foo &&= bar
        # ^^^^^^^^^^^^^
        def visit_class_variable_and_write_node(node)
          builder.op_assign(
            builder.assignable(builder.cvar(token(node.name_loc))),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # @@foo ||= bar
        # ^^^^^^^^^^^^^
        def visit_class_variable_or_write_node(node)
          builder.op_assign(
            builder.assignable(builder.cvar(token(node.name_loc))),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # @@foo, = bar
        # ^^^^^
        def visit_class_variable_target_node(node)
          builder.assignable(builder.cvar(token(node.location)))
        end

        # Foo
        # ^^^
        def visit_constant_read_node(node)
          builder.const([node.name, srange(node.location)])
        end

        # Foo = 1
        # ^^^^^^^
        #
        # Foo, Bar = 1
        # ^^^  ^^^
        def visit_constant_write_node(node)
          builder.assign(builder.assignable(builder.const([node.name, srange(node.name_loc)])), token(node.operator_loc), visit(node.value))
        end

        # Foo += bar
        # ^^^^^^^^^^^
        def visit_constant_operator_write_node(node)
          builder.op_assign(
            builder.assignable(builder.const([node.name, srange(node.name_loc)])),
            [node.binary_operator_loc.slice.chomp("="), srange(node.binary_operator_loc)],
            visit(node.value)
          )
        end

        # Foo &&= bar
        # ^^^^^^^^^^^^
        def visit_constant_and_write_node(node)
          builder.op_assign(
            builder.assignable(builder.const([node.name, srange(node.name_loc)])),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # Foo ||= bar
        # ^^^^^^^^^^^^
        def visit_constant_or_write_node(node)
          builder.op_assign(
            builder.assignable(builder.const([node.name, srange(node.name_loc)])),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # Foo, = bar
        # ^^^
        def visit_constant_target_node(node)
          builder.assignable(builder.const([node.name, srange(node.location)]))
        end

        # Foo::Bar
        # ^^^^^^^^
        def visit_constant_path_node(node)
          if node.parent.nil?
            builder.const_global(
              token(node.delimiter_loc),
              [node.name, srange(node.name_loc)]
            )
          else
            builder.const_fetch(
              visit(node.parent),
              token(node.delimiter_loc),
              [node.name, srange(node.name_loc)]
            )
          end
        end

        # Foo::Bar = 1
        # ^^^^^^^^^^^^
        #
        # Foo::Foo, Bar::Bar = 1
        # ^^^^^^^^  ^^^^^^^^
        def visit_constant_path_write_node(node)
          builder.assign(
            builder.assignable(visit(node.target)),
            token(node.operator_loc),
            visit(node.value)
          )
        end

        # Foo::Bar += baz
        # ^^^^^^^^^^^^^^^
        def visit_constant_path_operator_write_node(node)
          builder.op_assign(
            builder.assignable(visit(node.target)),
            [node.binary_operator_loc.slice.chomp("="), srange(node.binary_operator_loc)],
            visit(node.value)
          )
        end

        # Foo::Bar &&= baz
        # ^^^^^^^^^^^^^^^^
        def visit_constant_path_and_write_node(node)
          builder.op_assign(
            builder.assignable(visit(node.target)),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # Foo::Bar ||= baz
        # ^^^^^^^^^^^^^^^^
        def visit_constant_path_or_write_node(node)
          builder.op_assign(
            builder.assignable(visit(node.target)),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # Foo::Bar, = baz
        # ^^^^^^^^
        def visit_constant_path_target_node(node)
          builder.assignable(visit_constant_path_node(node))
        end

        # def foo; end
        # ^^^^^^^^^^^^
        #
        # def self.foo; end
        # ^^^^^^^^^^^^^^^^^
        def visit_def_node(node)
          if node.equal_loc
            if node.receiver
              builder.def_endless_singleton(
                token(node.def_keyword_loc),
                visit(node.receiver.is_a?(ParenthesesNode) ? node.receiver.body : node.receiver),
                token(node.operator_loc),
                token(node.name_loc),
                builder.args(token(node.lparen_loc), visit(node.parameters) || [], token(node.rparen_loc), false),
                token(node.equal_loc),
                node.body&.accept(copy_compiler(forwarding: find_forwarding(node.parameters)))
              )
            else
              builder.def_endless_method(
                token(node.def_keyword_loc),
                token(node.name_loc),
                builder.args(token(node.lparen_loc), visit(node.parameters) || [], token(node.rparen_loc), false),
                token(node.equal_loc),
                node.body&.accept(copy_compiler(forwarding: find_forwarding(node.parameters)))
              )
            end
          elsif node.receiver
            builder.def_singleton(
              token(node.def_keyword_loc),
              visit(node.receiver.is_a?(ParenthesesNode) ? node.receiver.body : node.receiver),
              token(node.operator_loc),
              token(node.name_loc),
              builder.args(token(node.lparen_loc), visit(node.parameters) || [], token(node.rparen_loc), false),
              node.body&.accept(copy_compiler(forwarding: find_forwarding(node.parameters))),
              token(node.end_keyword_loc)
            )
          else
            builder.def_method(
              token(node.def_keyword_loc),
              token(node.name_loc),
              builder.args(token(node.lparen_loc), visit(node.parameters) || [], token(node.rparen_loc), false),
              node.body&.accept(copy_compiler(forwarding: find_forwarding(node.parameters))),
              token(node.end_keyword_loc)
            )
          end
        end

        # defined? a
        # ^^^^^^^^^^
        #
        # defined?(a)
        # ^^^^^^^^^^^
        def visit_defined_node(node)
          builder.keyword_cmd(
            :defined?,
            token(node.keyword_loc),
            token(node.lparen_loc),
            [visit(node.value)],
            token(node.rparen_loc)
          )
        end

        # if foo then bar else baz end
        #                 ^^^^^^^^^^^^
        def visit_else_node(node)
          visit(node.statements)
        end

        # "foo #{bar}"
        #      ^^^^^^
        def visit_embedded_statements_node(node)
          builder.begin(
            token(node.opening_loc),
            visit(node.statements),
            token(node.closing_loc)
          )
        end

        # "foo #@bar"
        #      ^^^^^
        def visit_embedded_variable_node(node)
          visit(node.variable)
        end

        # begin; foo; ensure; bar; end
        #             ^^^^^^^^^^^^
        def visit_ensure_node(node)
          raise CompilationError, "Cannot directly compile ensure nodes"
        end

        # false
        # ^^^^^
        def visit_false_node(node)
          builder.false(token(node.location))
        end

        # foo => [*, bar, *]
        #        ^^^^^^^^^^^
        def visit_find_pattern_node(node)
          elements = [node.left, *node.requireds, node.right]

          if node.constant
            builder.const_pattern(visit(node.constant), token(node.opening_loc), builder.find_pattern(nil, visit_all(elements), nil), token(node.closing_loc))
          else
            builder.find_pattern(token(node.opening_loc), visit_all(elements), token(node.closing_loc))
          end
        end

        # 1.0
        # ^^^
        def visit_float_node(node)
          visit_numeric(node, builder.float([node.value, srange(node.location)]))
        end

        # for foo in bar do end
        # ^^^^^^^^^^^^^^^^^^^^^
        def visit_for_node(node)
          builder.for(
            token(node.for_keyword_loc),
            visit(node.index),
            token(node.in_keyword_loc),
            visit(node.collection),
            if (do_keyword_loc = node.do_keyword_loc)
              token(do_keyword_loc)
            else
              srange_find(node.collection.location.end_offset, (node.statements&.location || node.end_keyword_loc).start_offset, ";")
            end,
            visit(node.statements),
            token(node.end_keyword_loc)
          )
        end

        # def foo(...); bar(...); end
        #                   ^^^
        def visit_forwarding_arguments_node(node)
          builder.forwarded_args(token(node.location))
        end

        # def foo(...); end
        #         ^^^
        def visit_forwarding_parameter_node(node)
          builder.forward_arg(token(node.location))
        end

        # super
        # ^^^^^
        #
        # super {}
        # ^^^^^^^^
        def visit_forwarding_super_node(node)
          visit_block(
            builder.keyword_cmd(
              :zsuper,
              ["super", srange_offsets(node.location.start_offset, node.location.start_offset + 5)]
            ),
            node.block
          )
        end

        # $foo
        # ^^^^
        def visit_global_variable_read_node(node)
          builder.gvar(token(node.location))
        end

        # $foo = 1
        # ^^^^^^^^
        def visit_global_variable_write_node(node)
          builder.assign(
            builder.assignable(builder.gvar(token(node.name_loc))),
            token(node.operator_loc),
            visit(node.value)
          )
        end

        # $foo += bar
        # ^^^^^^^^^^^
        def visit_global_variable_operator_write_node(node)
          builder.op_assign(
            builder.assignable(builder.gvar(token(node.name_loc))),
            [node.binary_operator_loc.slice.chomp("="), srange(node.binary_operator_loc)],
            visit(node.value)
          )
        end

        # $foo &&= bar
        # ^^^^^^^^^^^^
        def visit_global_variable_and_write_node(node)
          builder.op_assign(
            builder.assignable(builder.gvar(token(node.name_loc))),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # $foo ||= bar
        # ^^^^^^^^^^^^
        def visit_global_variable_or_write_node(node)
          builder.op_assign(
            builder.assignable(builder.gvar(token(node.name_loc))),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # $foo, = bar
        # ^^^^
        def visit_global_variable_target_node(node)
          builder.assignable(builder.gvar([node.slice, srange(node.location)]))
        end

        # {}
        # ^^
        def visit_hash_node(node)
          builder.associate(
            token(node.opening_loc),
            visit_all(node.elements),
            token(node.closing_loc)
          )
        end

        # foo => {}
        #        ^^
        def visit_hash_pattern_node(node)
          elements = [*node.elements, *node.rest]

          if node.constant
            builder.const_pattern(visit(node.constant), token(node.opening_loc), builder.hash_pattern(nil, visit_all(elements), nil), token(node.closing_loc))
          else
            builder.hash_pattern(token(node.opening_loc), visit_all(elements), token(node.closing_loc))
          end
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
          if !node.if_keyword_loc
            builder.ternary(
              visit(node.predicate),
              token(node.then_keyword_loc),
              visit(node.statements),
              token(node.subsequent.else_keyword_loc),
              visit(node.subsequent)
            )
          elsif node.if_keyword_loc.start_offset == node.location.start_offset
            builder.condition(
              token(node.if_keyword_loc),
              visit(node.predicate),
              if (then_keyword_loc = node.then_keyword_loc)
                token(then_keyword_loc)
              else
                srange_find(node.predicate.location.end_offset, (node.statements&.location || node.subsequent&.location || node.end_keyword_loc).start_offset, ";")
              end,
              visit(node.statements),
              case node.subsequent
              when IfNode
                token(node.subsequent.if_keyword_loc)
              when ElseNode
                token(node.subsequent.else_keyword_loc)
              end,
              visit(node.subsequent),
              if node.if_keyword != "elsif"
                token(node.end_keyword_loc)
              end
            )
          else
            builder.condition_mod(
              visit(node.statements),
              visit(node.subsequent),
              token(node.if_keyword_loc),
              visit(node.predicate)
            )
          end
        end

        # 1i
        # ^^
        def visit_imaginary_node(node)
          visit_numeric(node, builder.complex([Complex(0, node.numeric.value), srange(node.location)]))
        end

        # { foo: }
        #   ^^^^
        def visit_implicit_node(node)
          raise CompilationError, "Cannot directly compile implicit nodes"
        end

        # foo { |bar,| }
        #           ^
        def visit_implicit_rest_node(node)
          raise CompilationError, "Cannot compile implicit rest nodes"
        end

        # case foo; in bar; end
        # ^^^^^^^^^^^^^^^^^^^^^
        def visit_in_node(node)
          pattern = nil
          guard = nil

          case node.pattern
          when IfNode
            pattern = within_pattern { |compiler| node.pattern.statements.accept(compiler) }
            guard = builder.if_guard(token(node.pattern.if_keyword_loc), visit(node.pattern.predicate))
          when UnlessNode
            pattern = within_pattern { |compiler| node.pattern.statements.accept(compiler) }
            guard = builder.unless_guard(token(node.pattern.keyword_loc), visit(node.pattern.predicate))
          else
            pattern = within_pattern { |compiler| node.pattern.accept(compiler) }
          end

          builder.in_pattern(
            token(node.in_loc),
            pattern,
            guard,
            if (then_loc = node.then_loc)
              token(then_loc)
            else
              srange_find(node.pattern.location.end_offset, node.statements&.location&.start_offset, ";")
            end,
            visit(node.statements)
          )
        end

        # foo[bar] += baz
        # ^^^^^^^^^^^^^^^
        def visit_index_operator_write_node(node)
          arguments = node.arguments&.arguments || []
          arguments << node.block if node.block

          builder.op_assign(
            builder.index(
              visit(node.receiver),
              token(node.opening_loc),
              visit_all(arguments),
              token(node.closing_loc)
            ),
            [node.binary_operator_loc.slice.chomp("="), srange(node.binary_operator_loc)],
            visit(node.value)
          )
        end

        # foo[bar] &&= baz
        # ^^^^^^^^^^^^^^^^
        def visit_index_and_write_node(node)
          arguments = node.arguments&.arguments || []
          arguments << node.block if node.block

          builder.op_assign(
            builder.index(
              visit(node.receiver),
              token(node.opening_loc),
              visit_all(arguments),
              token(node.closing_loc)
            ),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # foo[bar] ||= baz
        # ^^^^^^^^^^^^^^^^
        def visit_index_or_write_node(node)
          arguments = node.arguments&.arguments || []
          arguments << node.block if node.block

          builder.op_assign(
            builder.index(
              visit(node.receiver),
              token(node.opening_loc),
              visit_all(arguments),
              token(node.closing_loc)
            ),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # foo[bar], = 1
        # ^^^^^^^^
        def visit_index_target_node(node)
          builder.index_asgn(
            visit(node.receiver),
            token(node.opening_loc),
            visit_all(node.arguments.arguments),
            token(node.closing_loc),
          )
        end

        # @foo
        # ^^^^
        def visit_instance_variable_read_node(node)
          builder.ivar(token(node.location))
        end

        # @foo = 1
        # ^^^^^^^^
        def visit_instance_variable_write_node(node)
          builder.assign(
            builder.assignable(builder.ivar(token(node.name_loc))),
            token(node.operator_loc),
            visit(node.value)
          )
        end

        # @foo += bar
        # ^^^^^^^^^^^
        def visit_instance_variable_operator_write_node(node)
          builder.op_assign(
            builder.assignable(builder.ivar(token(node.name_loc))),
            [node.binary_operator_loc.slice.chomp("="), srange(node.binary_operator_loc)],
            visit(node.value)
          )
        end

        # @foo &&= bar
        # ^^^^^^^^^^^^
        def visit_instance_variable_and_write_node(node)
          builder.op_assign(
            builder.assignable(builder.ivar(token(node.name_loc))),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # @foo ||= bar
        # ^^^^^^^^^^^^
        def visit_instance_variable_or_write_node(node)
          builder.op_assign(
            builder.assignable(builder.ivar(token(node.name_loc))),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # @foo, = bar
        # ^^^^
        def visit_instance_variable_target_node(node)
          builder.assignable(builder.ivar(token(node.location)))
        end

        # 1
        # ^
        def visit_integer_node(node)
          visit_numeric(node, builder.integer([node.value, srange(node.location)]))
        end

        # /foo #{bar}/
        # ^^^^^^^^^^^^
        def visit_interpolated_regular_expression_node(node)
          builder.regexp_compose(
            token(node.opening_loc),
            string_nodes_from_interpolation(node, node.opening),
            [node.closing[0], srange_offsets(node.closing_loc.start_offset, node.closing_loc.start_offset + 1)],
            builder.regexp_options([node.closing[1..], srange_offsets(node.closing_loc.start_offset + 1, node.closing_loc.end_offset)])
          )
        end

        # if /foo #{bar}/ then end
        #    ^^^^^^^^^^^^
        alias visit_interpolated_match_last_line_node visit_interpolated_regular_expression_node

        # "foo #{bar}"
        # ^^^^^^^^^^^^
        def visit_interpolated_string_node(node)
          if node.heredoc?
            return visit_heredoc(node) { |children, closing| builder.string_compose(token(node.opening_loc), children, closing) }
          end

          builder.string_compose(
            token(node.opening_loc),
            string_nodes_from_interpolation(node, node.opening),
            token(node.closing_loc)
          )
        end

        # :"foo #{bar}"
        # ^^^^^^^^^^^^^
        def visit_interpolated_symbol_node(node)
          builder.symbol_compose(
            token(node.opening_loc),
            string_nodes_from_interpolation(node, node.opening),
            token(node.closing_loc)
          )
        end

        # `foo #{bar}`
        # ^^^^^^^^^^^^
        def visit_interpolated_x_string_node(node)
          if node.heredoc?
            return visit_heredoc(node) { |children, closing| builder.xstring_compose(token(node.opening_loc), children, closing) }
          end

          builder.xstring_compose(
            token(node.opening_loc),
            string_nodes_from_interpolation(node, node.opening),
            token(node.closing_loc)
          )
        end

        # -> { it }
        #      ^^
        def visit_it_local_variable_read_node(node)
          builder.ident([:it, srange(node.location)]).updated(:lvar)
        end

        # -> { it }
        # ^^^^^^^^^
        def visit_it_parameters_node(node)
          # FIXME: The builder _should_ always be a subclass of the prism builder.
          # Currently RuboCop passes in its own builder that always inherits from the
          # parser builder (which is lacking the `itarg` method). Once rubocop-ast
          # opts in to use the custom prism builder a warning can be emitted when
          # it is not the expected class, and eventually raise.
          # https://github.com/rubocop/rubocop-ast/pull/354
          if builder.is_a?(Translation::Parser::Builder)
            builder.itarg
          else
            builder.args(nil, [], nil, false)
          end
        end

        # foo(bar: baz)
        #     ^^^^^^^^
        def visit_keyword_hash_node(node)
          builder.associate(nil, visit_all(node.elements), nil)
        end

        # def foo(**bar); end
        #         ^^^^^
        #
        # def foo(**); end
        #         ^^
        def visit_keyword_rest_parameter_node(node)
          builder.kwrestarg(
            token(node.operator_loc),
            node.name ? [node.name, srange(node.name_loc)] : nil
          )
        end

        # -> {}
        # ^^^^^
        def visit_lambda_node(node)
          parameters = node.parameters
          implicit_parameters = parameters.is_a?(NumberedParametersNode) || parameters.is_a?(ItParametersNode)

          builder.block(
            builder.call_lambda(token(node.operator_loc)),
            [node.opening, srange(node.opening_loc)],
            if parameters.nil?
              builder.args(nil, [], nil, false)
            elsif implicit_parameters
              visit(node.parameters)
            else
              builder.args(
                token(node.parameters.opening_loc),
                visit(node.parameters),
                token(node.parameters.closing_loc),
                false
              )
            end,
            visit(node.body),
            [node.closing, srange(node.closing_loc)]
          )
        end

        # foo
        # ^^^
        def visit_local_variable_read_node(node)
          builder.ident([node.name, srange(node.location)]).updated(:lvar)
        end

        # foo = 1
        # ^^^^^^^
        def visit_local_variable_write_node(node)
          builder.assign(
            builder.assignable(builder.ident(token(node.name_loc))),
            token(node.operator_loc),
            visit(node.value)
          )
        end

        # foo += bar
        # ^^^^^^^^^^
        def visit_local_variable_operator_write_node(node)
          builder.op_assign(
            builder.assignable(builder.ident(token(node.name_loc))),
            [node.binary_operator_loc.slice.chomp("="), srange(node.binary_operator_loc)],
            visit(node.value)
          )
        end

        # foo &&= bar
        # ^^^^^^^^^^^
        def visit_local_variable_and_write_node(node)
          builder.op_assign(
            builder.assignable(builder.ident(token(node.name_loc))),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # foo ||= bar
        # ^^^^^^^^^^^
        def visit_local_variable_or_write_node(node)
          builder.op_assign(
            builder.assignable(builder.ident(token(node.name_loc))),
            [node.operator_loc.slice.chomp("="), srange(node.operator_loc)],
            visit(node.value)
          )
        end

        # foo, = bar
        # ^^^
        def visit_local_variable_target_node(node)
          if in_pattern
            builder.assignable(builder.match_var([node.name, srange(node.location)]))
          else
            builder.assignable(builder.ident(token(node.location)))
          end
        end

        # foo in bar
        # ^^^^^^^^^^
        def visit_match_predicate_node(node)
          builder.match_pattern_p(
            visit(node.value),
            token(node.operator_loc),
            within_pattern { |compiler| node.pattern.accept(compiler) }
          )
        end

        # foo => bar
        # ^^^^^^^^^^
        def visit_match_required_node(node)
          builder.match_pattern(
            visit(node.value),
            token(node.operator_loc),
            within_pattern { |compiler| node.pattern.accept(compiler) }
          )
        end

        # /(?<foo>foo)/ =~ bar
        # ^^^^^^^^^^^^^^^^^^^^
        def visit_match_write_node(node)
          builder.match_op(
            visit(node.call.receiver),
            token(node.call.message_loc),
            visit(node.call.arguments.arguments.first)
          )
        end

        # A node that is missing from the syntax tree. This is only used in the
        # case of a syntax error. The parser gem doesn't have such a concept, so
        # we invent our own here.
        def visit_missing_node(node)
          ::AST::Node.new(:missing, [], location: ::Parser::Source::Map.new(srange(node.location)))
        end

        # module Foo; end
        # ^^^^^^^^^^^^^^^
        def visit_module_node(node)
          builder.def_module(
            token(node.module_keyword_loc),
            visit(node.constant_path),
            node.body&.accept(copy_compiler(forwarding: [])),
            token(node.end_keyword_loc)
          )
        end

        # foo, bar = baz
        # ^^^^^^^^
        def visit_multi_target_node(node)
          builder.multi_lhs(
            token(node.lparen_loc),
            visit_all(multi_target_elements(node)),
            token(node.rparen_loc)
          )
        end

        # foo, bar = baz
        # ^^^^^^^^^^^^^^
        def visit_multi_write_node(node)
          elements = multi_target_elements(node)

          if elements.length == 1 && elements.first.is_a?(MultiTargetNode) && !node.rest
            elements = multi_target_elements(elements.first)
          end

          builder.multi_assign(
            builder.multi_lhs(
              token(node.lparen_loc),
              visit_all(elements),
              token(node.rparen_loc)
            ),
            token(node.operator_loc),
            visit(node.value)
          )
        end

        # next
        # ^^^^
        #
        # next foo
        # ^^^^^^^^
        def visit_next_node(node)
          builder.keyword_cmd(
            :next,
            token(node.keyword_loc),
            nil,
            visit(node.arguments) || [],
            nil
          )
        end

        # nil
        # ^^^
        def visit_nil_node(node)
          builder.nil(token(node.location))
        end

        # def foo(**nil); end
        #         ^^^^^
        def visit_no_keywords_parameter_node(node)
          if in_pattern
            builder.match_nil_pattern(token(node.operator_loc), token(node.keyword_loc))
          else
            builder.kwnilarg(token(node.operator_loc), token(node.keyword_loc))
          end
        end

        # -> { _1 + _2 }
        # ^^^^^^^^^^^^^^
        def visit_numbered_parameters_node(node)
          builder.numargs(node.maximum)
        end

        # $1
        # ^^
        def visit_numbered_reference_read_node(node)
          builder.nth_ref([node.number, srange(node.location)])
        end

        # def foo(bar: baz); end
        #         ^^^^^^^^
        def visit_optional_keyword_parameter_node(node)
          builder.kwoptarg([node.name, srange(node.name_loc)], visit(node.value))
        end

        # def foo(bar = 1); end
        #         ^^^^^^^
        def visit_optional_parameter_node(node)
          builder.optarg(token(node.name_loc), token(node.operator_loc), visit(node.value))
        end

        # a or b
        # ^^^^^^
        def visit_or_node(node)
          builder.logical_op(:or, visit(node.left), token(node.operator_loc), visit(node.right))
        end

        # def foo(bar, *baz); end
        #         ^^^^^^^^^
        def visit_parameters_node(node)
          params = []

          if node.requireds.any?
            node.requireds.each do |required|
              params <<
                if required.is_a?(RequiredParameterNode)
                  visit(required)
                else
                  required.accept(copy_compiler(in_destructure: true))
                end
            end
          end

          params.concat(visit_all(node.optionals)) if node.optionals.any?
          params << visit(node.rest) if !node.rest.nil? && !node.rest.is_a?(ImplicitRestNode)

          if node.posts.any?
            node.posts.each do |post|
              params <<
                if post.is_a?(RequiredParameterNode)
                  visit(post)
                else
                  post.accept(copy_compiler(in_destructure: true))
                end
            end
          end

          params.concat(visit_all(node.keywords)) if node.keywords.any?
          params << visit(node.keyword_rest) if !node.keyword_rest.nil?
          params << visit(node.block) if !node.block.nil?
          params
        end

        # ()
        # ^^
        #
        # (1)
        # ^^^
        def visit_parentheses_node(node)
          builder.begin(
            token(node.opening_loc),
            visit(node.body),
            token(node.closing_loc)
          )
        end

        # foo => ^(bar)
        #        ^^^^^^
        def visit_pinned_expression_node(node)
          expression = builder.begin(token(node.lparen_loc), visit(node.expression), token(node.rparen_loc))
          builder.pin(token(node.operator_loc), expression)
        end

        # foo = 1 and bar => ^foo
        #                    ^^^^
        def visit_pinned_variable_node(node)
          builder.pin(token(node.operator_loc), visit(node.variable))
        end

        # END {}
        def visit_post_execution_node(node)
          builder.postexe(
            token(node.keyword_loc),
            token(node.opening_loc),
            visit(node.statements),
            token(node.closing_loc)
          )
        end

        # BEGIN {}
        def visit_pre_execution_node(node)
          builder.preexe(
            token(node.keyword_loc),
            token(node.opening_loc),
            visit(node.statements),
            token(node.closing_loc)
          )
        end

        # The top-level program node.
        def visit_program_node(node)
          visit(node.statements)
        end

        # 0..5
        # ^^^^
        def visit_range_node(node)
          if node.exclude_end?
            builder.range_exclusive(
              visit(node.left),
              token(node.operator_loc),
              visit(node.right)
            )
          else
            builder.range_inclusive(
              visit(node.left),
              token(node.operator_loc),
              visit(node.right)
            )
          end
        end

        # if foo .. bar; end
        #    ^^^^^^^^^^
        alias visit_flip_flop_node visit_range_node

        # 1r
        # ^^
        def visit_rational_node(node)
          visit_numeric(node, builder.rational([node.value, srange(node.location)]))
        end

        # redo
        # ^^^^
        def visit_redo_node(node)
          builder.keyword_cmd(:redo, token(node.location))
        end

        # /foo/
        # ^^^^^
        def visit_regular_expression_node(node)
          parts =
            if node.content == ""
              []
            elsif node.content.include?("\n")
              string_nodes_from_line_continuations(node.unescaped, node.content, node.content_loc.start_offset, node.opening)
            else
              [builder.string_internal([node.unescaped, srange(node.content_loc)])]
            end

          builder.regexp_compose(
            token(node.opening_loc),
            parts,
            [node.closing[0], srange_offsets(node.closing_loc.start_offset, node.closing_loc.start_offset + 1)],
            builder.regexp_options([node.closing[1..], srange_offsets(node.closing_loc.start_offset + 1, node.closing_loc.end_offset)])
          )
        end

        # if /foo/ then end
        #    ^^^^^
        alias visit_match_last_line_node visit_regular_expression_node

        # def foo(bar:); end
        #         ^^^^
        def visit_required_keyword_parameter_node(node)
          builder.kwarg([node.name, srange(node.name_loc)])
        end

        # def foo(bar); end
        #         ^^^
        def visit_required_parameter_node(node)
          builder.arg(token(node.location))
        end

        # foo rescue bar
        # ^^^^^^^^^^^^^^
        def visit_rescue_modifier_node(node)
          builder.begin_body(
            visit(node.expression),
            [
              builder.rescue_body(
                token(node.keyword_loc),
                nil,
                nil,
                nil,
                nil,
                visit(node.rescue_expression)
              )
            ]
          )
        end

        # begin; rescue; end
        #        ^^^^^^^
        def visit_rescue_node(node)
          raise CompilationError, "Cannot directly compile rescue nodes"
        end

        # def foo(*bar); end
        #         ^^^^
        #
        # def foo(*); end
        #         ^
        def visit_rest_parameter_node(node)
          builder.restarg(token(node.operator_loc), token(node.name_loc))
        end

        # retry
        # ^^^^^
        def visit_retry_node(node)
          builder.keyword_cmd(:retry, token(node.location))
        end

        # return
        # ^^^^^^
        #
        # return 1
        # ^^^^^^^^
        def visit_return_node(node)
          builder.keyword_cmd(
            :return,
            token(node.keyword_loc),
            nil,
            visit(node.arguments) || [],
            nil
          )
        end

        # self
        # ^^^^
        def visit_self_node(node)
          builder.self(token(node.location))
        end

        # A shareable constant.
        def visit_shareable_constant_node(node)
          visit(node.write)
        end

        # class << self; end
        # ^^^^^^^^^^^^^^^^^^
        def visit_singleton_class_node(node)
          builder.def_sclass(
            token(node.class_keyword_loc),
            token(node.operator_loc),
            visit(node.expression),
            node.body&.accept(copy_compiler(forwarding: [])),
            token(node.end_keyword_loc)
          )
        end

        # __ENCODING__
        # ^^^^^^^^^^^^
        def visit_source_encoding_node(node)
          builder.accessible(builder.__ENCODING__(token(node.location)))
        end

        # __FILE__
        # ^^^^^^^^
        def visit_source_file_node(node)
          builder.accessible(builder.__FILE__(token(node.location)))
        end

        # __LINE__
        # ^^^^^^^^
        def visit_source_line_node(node)
          builder.accessible(builder.__LINE__(token(node.location)))
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
          if node.expression.nil? && forwarding.include?(:*)
            builder.forwarded_restarg(token(node.operator_loc))
          elsif in_destructure
            builder.restarg(token(node.operator_loc), token(node.expression&.location))
          elsif in_pattern
            builder.match_rest(token(node.operator_loc), token(node.expression&.location))
          else
            builder.splat(token(node.operator_loc), visit(node.expression))
          end
        end

        # A list of statements.
        def visit_statements_node(node)
          builder.compstmt(visit_all(node.body))
        end

        # "foo"
        # ^^^^^
        def visit_string_node(node)
          if node.heredoc?
            visit_heredoc(node.to_interpolated) { |children, closing| builder.string_compose(token(node.opening_loc), children, closing) }
          elsif node.opening == "?"
            builder.character([node.unescaped, srange(node.location)])
          elsif node.opening&.start_with?("%") && node.unescaped.empty?
            builder.string_compose(token(node.opening_loc), [], token(node.closing_loc))
          else
            parts =
              if node.content.include?("\n")
                string_nodes_from_line_continuations(node.unescaped, node.content, node.content_loc.start_offset, node.opening)
              else
                [builder.string_internal([node.unescaped, srange(node.content_loc)])]
              end

            builder.string_compose(
              token(node.opening_loc),
              parts,
              token(node.closing_loc)
            )
          end
        end

        # super(foo)
        # ^^^^^^^^^^
        def visit_super_node(node)
          arguments = node.arguments&.arguments || []
          block = node.block

          if block.is_a?(BlockArgumentNode)
            arguments = [*arguments, block]
            block = nil
          end

          visit_block(
            builder.keyword_cmd(
              :super,
              token(node.keyword_loc),
              token(node.lparen_loc),
              visit_all(arguments),
              token(node.rparen_loc)
            ),
            block
          )
        end

        # :foo
        # ^^^^
        def visit_symbol_node(node)
          if node.closing_loc.nil?
            if node.opening_loc.nil?
              builder.symbol_internal([node.unescaped, srange(node.location)])
            else
              builder.symbol([node.unescaped, srange(node.location)])
            end
          else
            parts =
              if node.value == ""
                []
              elsif node.value.include?("\n")
                string_nodes_from_line_continuations(node.unescaped, node.value, node.value_loc.start_offset, node.opening)
              else
                [builder.string_internal([node.unescaped, srange(node.value_loc)])]
              end

            builder.symbol_compose(
              token(node.opening_loc),
              parts,
              token(node.closing_loc)
            )
          end
        end

        # true
        # ^^^^
        def visit_true_node(node)
          builder.true(token(node.location))
        end

        # undef foo
        # ^^^^^^^^^
        def visit_undef_node(node)
          builder.undef_method(token(node.keyword_loc), visit_all(node.names))
        end

        # unless foo; bar end
        # ^^^^^^^^^^^^^^^^^^^
        #
        # bar unless foo
        # ^^^^^^^^^^^^^^
        def visit_unless_node(node)
          if node.keyword_loc.start_offset == node.location.start_offset
            builder.condition(
              token(node.keyword_loc),
              visit(node.predicate),
              if (then_keyword_loc = node.then_keyword_loc)
                token(then_keyword_loc)
              else
                srange_find(node.predicate.location.end_offset, (node.statements&.location || node.else_clause&.location || node.end_keyword_loc).start_offset, ";")
              end,
              visit(node.else_clause),
              token(node.else_clause&.else_keyword_loc),
              visit(node.statements),
              token(node.end_keyword_loc)
            )
          else
            builder.condition_mod(
              visit(node.else_clause),
              visit(node.statements),
              token(node.keyword_loc),
              visit(node.predicate)
            )
          end
        end

        # until foo; bar end
        # ^^^^^^^^^^^^^^^^^^
        #
        # bar until foo
        # ^^^^^^^^^^^^^
        def visit_until_node(node)
          if node.location.start_offset == node.keyword_loc.start_offset
            builder.loop(
              :until,
              token(node.keyword_loc),
              visit(node.predicate),
              if (do_keyword_loc = node.do_keyword_loc)
                token(do_keyword_loc)
              else
                srange_find(node.predicate.location.end_offset, (node.statements&.location || node.closing_loc).start_offset, ";")
              end,
              visit(node.statements),
              token(node.closing_loc)
            )
          else
            builder.loop_mod(
              :until,
              visit(node.statements),
              token(node.keyword_loc),
              visit(node.predicate)
            )
          end
        end

        # case foo; when bar; end
        #           ^^^^^^^^^^^^^
        def visit_when_node(node)
          builder.when(
            token(node.keyword_loc),
            visit_all(node.conditions),
            if (then_keyword_loc = node.then_keyword_loc)
              token(then_keyword_loc)
            else
              srange_find(node.conditions.last.location.end_offset, node.statements&.location&.start_offset, ";")
            end,
            visit(node.statements)
          )
        end

        # while foo; bar end
        # ^^^^^^^^^^^^^^^^^^
        #
        # bar while foo
        # ^^^^^^^^^^^^^
        def visit_while_node(node)
          if node.location.start_offset == node.keyword_loc.start_offset
            builder.loop(
              :while,
              token(node.keyword_loc),
              visit(node.predicate),
              if (do_keyword_loc = node.do_keyword_loc)
                token(do_keyword_loc)
              else
                srange_find(node.predicate.location.end_offset, (node.statements&.location || node.closing_loc).start_offset, ";")
              end,
              visit(node.statements),
              token(node.closing_loc)
            )
          else
            builder.loop_mod(
              :while,
              visit(node.statements),
              token(node.keyword_loc),
              visit(node.predicate)
            )
          end
        end

        # `foo`
        # ^^^^^
        def visit_x_string_node(node)
          if node.heredoc?
            return visit_heredoc(node.to_interpolated) { |children, closing| builder.xstring_compose(token(node.opening_loc), children, closing) }
          end

          parts =
            if node.content == ""
              []
            elsif node.content.include?("\n")
              string_nodes_from_line_continuations(node.unescaped, node.content, node.content_loc.start_offset, node.opening)
            else
              [builder.string_internal([node.unescaped, srange(node.content_loc)])]
            end

          builder.xstring_compose(
            token(node.opening_loc),
            parts,
            token(node.closing_loc)
          )
        end

        # yield
        # ^^^^^
        #
        # yield 1
        # ^^^^^^^
        def visit_yield_node(node)
          builder.keyword_cmd(
            :yield,
            token(node.keyword_loc),
            token(node.lparen_loc),
            visit(node.arguments) || [],
            token(node.rparen_loc)
          )
        end

        private

        # Initialize a new compiler with the given option overrides, used to
        # visit a subtree with the given options.
        def copy_compiler(forwarding: self.forwarding, in_destructure: self.in_destructure, in_pattern: self.in_pattern)
          Compiler.new(parser, offset_cache, forwarding: forwarding, in_destructure: in_destructure, in_pattern: in_pattern)
        end

        # When *, **, &, or ... are used as an argument in a method call, we
        # check if they were allowed by the current context. To determine that
        # we build this lookup table.
        def find_forwarding(node)
          return [] if node.nil?

          forwarding = []
          forwarding << :* if node.rest.is_a?(RestParameterNode) && node.rest.name.nil?
          forwarding << :** if node.keyword_rest.is_a?(KeywordRestParameterNode) && node.keyword_rest.name.nil?
          forwarding << :& if !node.block.nil? && node.block.name.nil?
          forwarding |= [:&, :"..."] if node.keyword_rest.is_a?(ForwardingParameterNode)

          forwarding
        end

        # Returns the set of targets for a MultiTargetNode or a MultiWriteNode.
        def multi_target_elements(node)
          elements = [*node.lefts]
          elements << node.rest if !node.rest.nil? && !node.rest.is_a?(ImplicitRestNode)
          elements.concat(node.rights)
          elements
        end

        # Negate the value of a numeric node. This is a special case where you
        # have a negative sign on one line and then a number on the next line.
        # In normal Ruby, this will always be a method call. The parser gem,
        # however, marks this as a numeric literal. We have to massage the tree
        # here to get it into the correct form.
        def numeric_negate(message_loc, receiver)
          case receiver.type
          when :integer_node, :float_node
            receiver.copy(value: -receiver.value, location: message_loc.join(receiver.location))
          when :rational_node
            receiver.copy(numerator: -receiver.numerator, location: message_loc.join(receiver.location))
          when :imaginary_node
            receiver.copy(numeric: numeric_negate(message_loc, receiver.numeric), location: message_loc.join(receiver.location))
          end
        end

        # Blocks can have a special set of parameters that automatically expand
        # when given arrays if they have a single required parameter and no
        # other parameters.
        def procarg0?(parameters)
          parameters &&
            parameters.requireds.length == 1 &&
            parameters.optionals.empty? &&
            parameters.rest.nil? &&
            parameters.posts.empty? &&
            parameters.keywords.empty? &&
            parameters.keyword_rest.nil? &&
            parameters.block.nil?
        end

        # Locations in the parser gem AST are generated using this class. We
        # store a reference to its constant to make it slightly faster to look
        # up.
        Range = ::Parser::Source::Range

        # Constructs a new source range from the given start and end offsets.
        def srange(location)
          Range.new(source_buffer, offset_cache[location.start_offset], offset_cache[location.end_offset]) if location
        end

        # Constructs a new source range from the given start and end offsets.
        def srange_offsets(start_offset, end_offset)
          Range.new(source_buffer, offset_cache[start_offset], offset_cache[end_offset])
        end

        # Constructs a new source range by finding the given character between
        # the given start offset and end offset. If the needle is not found, it
        # returns nil. Importantly it does not search past newlines or comments.
        #
        # Note that end_offset is allowed to be nil, in which case this will
        # search until the end of the string.
        def srange_find(start_offset, end_offset, character)
          if (match = source_buffer.source.byteslice(start_offset...end_offset)[/\A\s*#{character}/])
            final_offset = start_offset + match.bytesize
            [character, Range.new(source_buffer, offset_cache[final_offset - character.bytesize], offset_cache[final_offset])]
          end
        end

        # Transform a location into a token that the parser gem expects.
        def token(location)
          [location.slice, Range.new(source_buffer, offset_cache[location.start_offset], offset_cache[location.end_offset])] if location
        end

        # Visit a block node on a call.
        def visit_block(call, block)
          if block
            parameters = block.parameters
            implicit_parameters = parameters.is_a?(NumberedParametersNode) || parameters.is_a?(ItParametersNode)

            builder.block(
              call,
              token(block.opening_loc),
              if parameters.nil?
                builder.args(nil, [], nil, false)
              elsif implicit_parameters
                visit(parameters)
              else
                builder.args(
                  token(parameters.opening_loc),
                  if procarg0?(parameters.parameters)
                    parameter = parameters.parameters.requireds.first
                    visited = parameter.is_a?(RequiredParameterNode) ? visit(parameter) : parameter.accept(copy_compiler(in_destructure: true))
                    [builder.procarg0(visited)].concat(visit_all(parameters.locals))
                  else
                    visit(parameters)
                  end,
                  token(parameters.closing_loc),
                  false
                )
              end,
              visit(block.body),
              token(block.closing_loc)
            )
          else
            call
          end
        end

        # Visit a heredoc that can be either a string or an xstring.
        def visit_heredoc(node)
          children = Array.new
          indented = false

          # If this is a dedenting heredoc, then we need to insert the opening
          # content into the children as well.
          if node.opening.start_with?("<<~") && node.parts.length > 0 && !node.parts.first.is_a?(StringNode)
            location = node.parts.first.location
            location = location.copy(start_offset: location.start_offset - location.start_line_slice.bytesize)
            children << builder.string_internal(token(location))
            indented = true
          end

          node.parts.each do |part|
            pushing =
              if part.is_a?(StringNode) && part.content.include?("\n")
                string_nodes_from_line_continuations(part.unescaped, part.content, part.location.start_offset, node.opening)
              else
                [visit(part)]
              end

            pushing.each do |child|
              if child.type == :str && child.children.last == ""
                # nothing
              elsif child.type == :str && children.last && children.last.type == :str && !children.last.children.first.end_with?("\n")
                appendee = children[-1]

                location = appendee.loc
                location = location.with_expression(location.expression.join(child.loc.expression))

                children[-1] = appendee.updated(:str, ["#{appendee.children.first}#{child.children.first}"], location: location)
              else
                children << child
              end
            end
          end

          closing = node.closing
          closing_t = [closing.chomp, srange_offsets(node.closing_loc.start_offset, node.closing_loc.end_offset - (closing[/\s+$/]&.length || 0))]
          composed = yield children, closing_t

          composed = composed.updated(nil, children[1..-1]) if indented
          composed
        end

        # Visit a numeric node and account for the optional sign.
        def visit_numeric(node, value)
          if (slice = node.slice).match?(/^[+-]/)
            builder.unary_num(
              [slice[0].to_sym, srange_offsets(node.location.start_offset, node.location.start_offset + 1)],
              value
            )
          else
            value
          end
        end

        # Within the given block, track that we're within a pattern.
        def within_pattern
          begin
            parser.pattern_variables.push
            yield copy_compiler(in_pattern: true)
          ensure
            parser.pattern_variables.pop
          end
        end

        # When the content of a string node is split across multiple lines, the
        # parser gem creates individual string nodes for each line the content is part of.
        def string_nodes_from_interpolation(node, opening)
          node.parts.flat_map do |part|
            if part.type == :string_node && part.content.include?("\n") && part.opening_loc.nil?
              string_nodes_from_line_continuations(part.unescaped, part.content, part.content_loc.start_offset, opening)
            else
              visit(part)
            end
          end
        end

        # Create parser string nodes from a single prism node. The parser gem
        # "glues" strings together when a line continuation is encountered.
        def string_nodes_from_line_continuations(unescaped, escaped, start_offset, opening)
          unescaped = unescaped.lines
          escaped = escaped.lines
          percent_array = opening&.start_with?("%w", "%W", "%i", "%I")
          regex = opening == "/" || opening&.start_with?("%r")

          # Non-interpolating strings
          if opening&.end_with?("'") || opening&.start_with?("%q", "%s", "%w", "%i")
            current_length = 0
            current_line = +""

            escaped.filter_map.with_index do |escaped_line, index|
              unescaped_line = unescaped.fetch(index, "")
              current_length += escaped_line.bytesize
              current_line << unescaped_line

              # Glue line continuations together. Only %w and %i arrays can contain these.
              if percent_array && escaped_line[/(\\)*\n$/, 1]&.length&.odd?
                next unless index == escaped.count - 1
              end
              s = builder.string_internal([current_line, srange_offsets(start_offset, start_offset + current_length)])
              start_offset += escaped_line.bytesize
              current_line = +""
              current_length = 0
              s
            end
          else
            escaped_lengths = []
            normalized_lengths = []
            # Keeps track of where an unescaped line should start a new token. An unescaped
            # \n would otherwise be indistinguishable from the actual newline at the end of
            # of the line. The parser gem only emits a new string node at "real" newlines,
            # line continuations don't start a new node as well.
            do_next_tokens = []

            escaped
              .chunk_while { |before, after| before[/(\\*)\r?\n$/, 1]&.length&.odd? || false }
              .each do |lines|
                escaped_lengths << lines.sum(&:bytesize)

                unescaped_lines_count =
                  if regex
                    0 # Will always be preserved as is
                  else
                    lines.sum do |line|
                      count = line.scan(/(\\*)n/).count { |(backslashes)| backslashes&.length&.odd? }
                      count -= 1 if !line.end_with?("\n") && count > 0
                      count
                    end
                  end

                extra = 1
                extra = lines.count if percent_array # Account for line continuations in percent arrays

                normalized_lengths.concat(Array.new(unescaped_lines_count + extra, 0))
                normalized_lengths[-1] = lines.sum { |line| line.bytesize }
                do_next_tokens.concat(Array.new(unescaped_lines_count + extra, false))
                do_next_tokens[-1] = true
              end

            current_line = +""
            current_normalized_length = 0

            emitted_count = 0
            unescaped.filter_map.with_index do |unescaped_line, index|
              current_line << unescaped_line
              current_normalized_length += normalized_lengths.fetch(index, 0)

              if do_next_tokens[index]
                inner_part = builder.string_internal([current_line, srange_offsets(start_offset, start_offset + current_normalized_length)])
                start_offset += escaped_lengths.fetch(emitted_count, 0)
                current_line = +""
                current_normalized_length = 0
                emitted_count += 1
                inner_part
              else
                nil
              end
            end
          end
        end
      end
    end
  end
end
