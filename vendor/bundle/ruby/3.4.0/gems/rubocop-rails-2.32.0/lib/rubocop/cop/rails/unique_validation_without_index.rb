# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # When you define a uniqueness validation in Active Record model,
      # you also should add a unique index for the column. There are two reasons.
      # First, duplicated records may occur even if Active Record's validation
      # is defined.
      # Second, it will cause slow queries. The validation executes a `SELECT`
      # statement with the target column when inserting/updating a record.
      # If the column does not have an index and the table is large,
      # the query will be heavy.
      #
      # Note that the cop does nothing if db/schema.rb does not exist.
      #
      # @example
      #   # bad - if the schema does not have a unique index
      #   validates :account, uniqueness: true
      #
      #   # good - if the schema has a unique index
      #   validates :account, uniqueness: true
      #
      #   # good - even if the schema does not have a unique index
      #   validates :account, length: { minimum: MIN_LENGTH }
      #
      class UniqueValidationWithoutIndex < Base
        include ActiveRecordHelper

        MSG = 'Uniqueness validation should have a unique index on the database column.'
        RESTRICT_ON_SEND = %i[validates].freeze

        def on_send(node)
          return unless schema
          return unless (uniqueness_part = uniqueness_part(node))
          return if uniqueness_part.falsey_literal? || condition_part?(node, uniqueness_part)

          klass, table, names = find_schema_information(node, uniqueness_part)
          return unless names
          return if with_index?(klass, table, names)

          add_offense(node)
        end

        private

        def find_schema_information(node, uniqueness_part)
          klass = class_node(node)
          return unless klass

          table = schema.table_by(name: table_name(klass))
          names = column_names(node, uniqueness_part)

          [klass, table, names]
        end

        def with_index?(klass, table, names)
          # Compatibility for Rails 4.2.
          add_indices = schema.add_indices_by(table_name: table_name(klass))

          (table.indices + add_indices).any? do |index|
            index.unique && (index.columns.to_set == names || include_column_names_in_expression_index?(index, names))
          end
        end

        def include_column_names_in_expression_index?(index, column_names)
          return false unless (expression_index = index.expression)

          column_names.all? do |column_name|
            expression_index.include?(column_name)
          end
        end

        def column_names(node, uniqueness_part)
          arg = node.first_argument
          return unless arg.type?(:str, :sym)

          ret = [arg.value]
          names_from_scope = column_names_from_scope(uniqueness_part)
          ret.concat(names_from_scope) if names_from_scope

          ret = ret.flat_map do |name|
            klass = class_node(node)
            resolve_relation_into_column(
              name: name.to_s,
              class_node: klass,
              table: schema.table_by(name: table_name(klass))
            )
          end
          ret.include?(nil) ? nil : ret.to_set
        end

        def column_names_from_scope(uniqueness_part)
          return unless uniqueness_part.hash_type?

          scope = find_scope(uniqueness_part)
          return unless scope

          scope = unfreeze_scope(scope)

          case scope.type
          when :sym, :str
            [scope.value]
          when :array
            array_node_to_array(scope)
          end
        end

        def find_scope(pairs)
          pairs.each_pair.find do |pair|
            key = pair.key
            next unless key.sym_type? && key.value == :scope

            break pair.value
          end
        end

        def unfreeze_scope(scope)
          scope.send_type? && scope.method?(:freeze) ? scope.children.first : scope
        end

        def class_node(node)
          node.each_ancestor.find(&:class_type?)
        end

        def uniqueness_part(node)
          pairs = node.last_argument
          return unless pairs&.hash_type?

          pairs.each_pair.find do |pair|
            next unless pair.key.sym_type? && pair.key.value == :uniqueness

            break pair.value
          end
        end

        def condition_part?(node, uniqueness_node)
          pairs = node.last_argument
          return false unless pairs.hash_type?
          return true if condition_hash_part?(pairs, keys: %i[if unless])
          return false unless uniqueness_node.hash_type?

          condition_hash_part?(uniqueness_node, keys: %i[if unless conditions])
        end

        def condition_hash_part?(pairs, keys:)
          pairs.each_pair.any? do |pair|
            key = pair.key
            next unless key.sym_type?

            keys.include?(key.value)
          end
        end

        def array_node_to_array(node)
          node.values.map do |elm|
            case elm.type
            when :str, :sym
              elm.value
            else
              return nil
            end
          end
        end
      end
    end
  end
end
