# frozen_string_literal: true

require "dry/schema/constants"

module Dry
  module Schema
    # @api private
    module Info
      # @api private
      class SchemaCompiler
        PREDICATE_TO_TYPE = {
          array?: "array",
          bool?: "bool",
          date?: "date",
          date_time?: "date_time",
          decimal?: "float",
          float?: "float",
          hash?: "hash",
          int?: "integer",
          nil?: "nil",
          str?: "string",
          time?: "time"
        }.freeze

        # @api private
        attr_reader :keys

        # @api private
        def initialize
          @keys = EMPTY_HASH.dup
        end

        # @api private
        def to_h
          {keys: keys}
        end

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
          target = (key = opts[:key]) ? self.class.new : self

          node.each { |child| target.visit(child, opts) }

          return unless key

          target_info = opts[:member] ? {member: target.to_h} : target.to_h
          type = opts[:member] ? "array" : "hash"

          keys.update(key => {**keys[key], type: type, **target_info})
        end

        # @api private
        def visit_and(node, opts = EMPTY_HASH)
          left, right = node

          visit(left, opts)
          visit(right, opts)
        end

        # @api private
        def visit_implication(node, opts = EMPTY_HASH)
          case node
          in [:not, [:predicate, [:nil?, _]]], el
            visit(el, {**opts, nullable: true})
          else
            node.each do |el|
              visit(el, {**opts, required: false})
            end
          end
        end

        # @api private
        def visit_each(node, opts = EMPTY_HASH)
          visit(node, {**opts, member: true})
        end

        # @api private
        def visit_key(node, opts = EMPTY_HASH)
          name, rest = node
          visit(rest, {**opts, key: name, required: true})
        end

        # @api private
        def visit_predicate(node, opts = EMPTY_HASH)
          name, rest = node

          key = opts[:key]

          if name.equal?(:key?)
            keys[rest[0][1]] = {
              required: opts.fetch(:required, true)
            }
          else
            type = PREDICATE_TO_TYPE[name]
            nullable = opts.fetch(:nullable, false)
            assign_type(key, type, nullable) if type
          end
        end

        # @api private
        def assign_type(key, type, nullable)
          if keys[key][:type]
            keys[key][:member] = type
          else
            keys[key][:type] = type
            keys[key][:nullable] = nullable
          end
        end
      end
    end
  end
end
