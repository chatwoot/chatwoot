# frozen_string_literal: true

require "dry/struct"

module Dry
  module Schema
    module Macros
      class StructToSchema < ::Dry::Struct::Compiler
        def call(struct)
          visit(struct.to_ast)
        end

        # strip away structs from AST
        def visit_struct(node)
          _, ast = node
          visit(ast)
        end
      end

      Hash.option :struct_compiler, default: proc { StructToSchema.new(schema_dsl.config.types) }

      Hash.prepend(::Module.new {
        def call(*args)
          if args.size >= 1 && struct?(args[0])
            if block_given?
              raise ArgumentError, "blocks are not supported when using " \
                                   "a struct class (#{name.inspect} => #{args[0]})"
            end

            schema = struct_compiler.(args[0])

            super(schema, *args.drop(1))
            type(schema_dsl.types[name].constructor(schema))
          else
            super
          end
        end

        private

        def struct?(type)
          type.is_a?(::Class) && type <= ::Dry::Struct
        end
      })
    end

    PredicateInferrer::Compiler.alias_method(:visit_struct, :visit_hash)
    PrimitiveInferrer::Compiler.alias_method(:visit_struct, :visit_hash)
  end
end
