# frozen_string_literal: true

module Dry
  module Types
    # @api private
    class Compiler
      extend ::Dry::Core::Deprecations[:"dry-types"]

      attr_reader :registry

      def initialize(registry)
        @registry = registry
      end

      def call(ast) = visit(ast)

      def visit(node)
        type, body = node
        send(:"visit_#{type}", body)
      end

      def visit_constrained(node)
        nominal, rule = node
        type = visit(nominal)
        type.constrained_type.new(type, rule: visit_rule(rule))
      end

      def visit_constructor(node)
        nominal, fn = node
        primitive = visit(nominal)
        primitive.constructor(compile_fn(fn))
      end

      def visit_lax(node)
        Types::Lax.new(visit(node))
      end
      deprecate(:visit_safe, :visit_lax)

      def visit_nominal(node)
        type, meta = node
        nominal_name = "nominal.#{Types.identifier(type)}"

        if registry.registered?(nominal_name)
          registry[nominal_name].meta(meta)
        else
          Nominal.new(type, meta: meta)
        end
      end

      def visit_rule(node)
        ::Dry::Types.rule_compiler.([node])[0]
      end

      def visit_sum(node)
        *types, meta = node
        types.map { |type| visit(type) }.reduce(:|).meta(meta)
      end

      def visit_array(node)
        member, meta = node
        member = visit(member) unless member.is_a?(::Class)
        registry["nominal.array"].of(member).meta(meta)
      end

      def visit_hash(node)
        opts, meta = node
        registry["nominal.hash"].with(**opts, meta: meta)
      end

      def visit_schema(node)
        keys, options, meta = node
        registry["nominal.hash"].schema(keys.map { |key| visit(key) }).with(**options, meta: meta)
      end

      def visit_json_hash(node)
        keys, meta = node
        registry["json.hash"].schema(keys.map { |key| visit(key) }, meta)
      end

      def visit_json_array(node)
        member, meta = node
        registry["json.array"].of(visit(member)).meta(meta)
      end

      def visit_params_hash(node)
        keys, meta = node
        registry["params.hash"].schema(keys.map { |key| visit(key) }, meta)
      end

      def visit_params_array(node)
        member, meta = node
        registry["params.array"].of(visit(member)).meta(meta)
      end

      def visit_key(node)
        name, required, type = node
        Schema::Key.new(visit(type), name, required: required)
      end

      def visit_enum(node)
        type, mapping = node
        Enum.new(visit(type), mapping: mapping)
      end

      def visit_map(node)
        key_type, value_type, meta = node
        registry["nominal.hash"].map(visit(key_type), visit(value_type)).meta(meta)
      end

      def visit_any(meta)
        registry["any"].meta(meta)
      end

      def compile_fn(fn)
        type, *node = fn

        case type
        when :id
          ::Dry::Types::FnContainer[node.fetch(0)]
        when :callable
          node.fetch(0)
        when :method
          target, method = node
          target.method(method)
        else
          raise ::ArgumentError, "Cannot build callable from #{fn.inspect}"
        end
      end
    end
  end
end
