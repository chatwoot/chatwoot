# frozen_string_literal: true

require "dry/schema/constants"

module Dry
  module Schema
    # @api private
    module JSONSchema
      # @api private
      class SchemaCompiler
        # An error raised when a predicate cannot be converted
        UnknownConversionError = ::Class.new(::StandardError)

        IDENTITY = ->(v, _) { v }.freeze
        TO_INTEGER = ->(v, _) { v.to_i }.freeze

        PREDICATE_TO_TYPE = {
          array?: {type: "array"},
          bool?: {type: "boolean"},
          date?: {type: "string", format: "date"},
          date_time?: {type: "string", format: "date-time"},
          decimal?: {type: "number"},
          float?: {type: "number"},
          hash?: {type: "object"},
          int?: {type: "integer"},
          nil?: {type: "null"},
          str?: {type: "string"},
          time?: {type: "string", format: "time"},
          min_size?: {minLength: TO_INTEGER},
          max_size?: {maxLength: TO_INTEGER},
          included_in?: {enum: ->(v, _) { v.to_a }},
          filled?: EMPTY_HASH,
          uri?: {format: "uri"},
          uuid_v1?: {
            pattern: "^[0-9A-F]{8}-[0-9A-F]{4}-1[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$"
          },
          uuid_v2?: {
            pattern: "^[0-9A-F]{8}-[0-9A-F]{4}-2[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$"
          },
          uuid_v3?: {
            pattern: "^[0-9A-F]{8}-[0-9A-F]{4}-3[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$"
          },
          uuid_v4?: {
            pattern: "^[a-f0-9]{8}-?[a-f0-9]{4}-?4[a-f0-9]{3}-?[89ab][a-f0-9]{3}-?[a-f0-9]{12}$"
          },
          uuid_v5?: {
            pattern: "^[0-9A-F]{8}-[0-9A-F]{4}-5[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$"
          },
          gt?: {exclusiveMinimum: IDENTITY},
          gteq?: {minimum: IDENTITY},
          lt?: {exclusiveMaximum: IDENTITY},
          lteq?: {maximum: IDENTITY},
          odd?: {type: "integer", not: {multipleOf: 2}},
          even?: {type: "integer", multipleOf: 2}
        }.freeze

        # @api private
        attr_reader :keys, :required

        # @api private
        def initialize(root: false, loose: false)
          @keys = EMPTY_HASH.dup
          @required = Set.new
          @root = root
          @loose = loose
        end

        # @api private
        def to_hash
          result = {}
          result[:$schema] = "http://json-schema.org/draft-06/schema#" if root?
          result.merge!(type: "object", properties: keys, required: required.to_a)
          result
        end

        alias_method :to_h, :to_hash

        # @api private
        def call(ast)
          visit(ast)
        end

        # @api private
        def visit(node, opts = EMPTY_HASH)
          meth, rest = node
          public_send(:"visit_#{meth}", rest, opts)
        end

        # @api private
        def visit_set(node, opts = EMPTY_HASH)
          target = (key = opts[:key]) ? self.class.new(loose: loose?) : self

          node.map { |child| target.visit(child, opts.except(:member)) }

          return unless key

          target_info = opts[:member] ? {items: target.to_h} : target.to_h
          type = opts[:member] ? "array" : "object"

          merge_opts!(keys[key], {type: type, **target_info})
        end

        # @api private
        def visit_and(node, opts = EMPTY_HASH)
          left, right = node

          # We need to know the type first to apply filled macro
          if left[1][0] == :filled?
            visit(right, opts)
            visit(left, opts)
          else
            visit(left, opts)
            visit(right, opts)
          end
        end

        # @api private
        def visit_or(node, opts = EMPTY_HASH)
          node.each do |child|
            c = self.class.new(loose: loose?)
            c.keys.update(subschema: {})
            c.visit(child, opts.merge(key: :subschema))

            any_of = (keys[opts[:key]][:anyOf] ||= [])
            any_of << c.keys[:subschema]
          end
        end

        # @api private
        def visit_implication(node, opts = EMPTY_HASH)
          node.each do |el|
            visit(el, **opts, required: false)
          end
        end

        # @api private
        def visit_each(node, opts = EMPTY_HASH)
          visit(node, opts.merge(member: true))
        end

        # @api private
        def visit_key(node, opts = EMPTY_HASH)
          name, rest = node

          if opts.fetch(:required, :true)
            required << name.to_s
          else
            opts.delete(:required)
          end

          visit(rest, opts.merge(key: name))
        end

        # @api private
        def visit_not(node, opts = EMPTY_HASH)
          _name, rest = node

          visit_predicate(rest, opts)
        end

        # @api private
        def visit_predicate(node, opts = EMPTY_HASH)
          name, rest = node

          if name.equal?(:key?)
            prop_name = rest[0][1]
            keys[prop_name] = {}
          else
            target = keys[opts[:key]]
            type_opts = fetch_type_opts_for_predicate(name, rest, target)

            if target[:type]&.include?("array")
              target[:items] ||= {}
              merge_opts!(target[:items], type_opts)
            else
              merge_opts!(target, type_opts)
            end
          end
        end

        # @api private
        def fetch_type_opts_for_predicate(name, rest, target)
          type_opts = PREDICATE_TO_TYPE.fetch(name) do
            raise_unknown_conversion_error!(:predicate, name) unless loose?

            EMPTY_HASH
          end.dup
          type_opts.transform_values! { |v| v.respond_to?(:call) ? v.call(rest[0][1], target) : v }
          type_opts.merge!(fetch_filled_options(target[:type], target)) if name == :filled?
          type_opts
        end

        # @api private
        def fetch_filled_options(type, _target)
          case type
          when "string"
            {minLength: 1}
          when "array"
            raise_unknown_conversion_error!(:type, :array) unless loose?

            {not: {type: "null"}}
          else
            {not: {type: "null"}}
          end
        end

        # @api private
        def merge_opts!(orig_opts, new_opts)
          new_type = new_opts[:type]
          orig_type = orig_opts[:type]

          if orig_type && new_type && orig_type != new_type
            new_opts[:type] = [orig_type, new_type].flatten.uniq
          end

          orig_opts.merge!(new_opts)
        end

        # @api private
        def root?
          @root
        end

        # @api private
        def loose?
          @loose
        end

        def raise_unknown_conversion_error!(type, name)
          message = <<~MSG
            Could not find an equivalent conversion for #{type} #{name.inspect}.

            This means that your generated JSON schema may be missing this validation.

            You can ignore this by generating the schema in "loose" mode, i.e.:
                my_schema.json_schema(loose: true)
          MSG

          raise UnknownConversionError, message.chomp
        end
      end
    end
  end
end
